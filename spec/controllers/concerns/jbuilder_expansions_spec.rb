# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

describe Controllers::ApiNew::JbuilderExpansions do 

	

	describe "#handle_expansion" do
		def convert_to_json(tree)
			JSON::parse(tree)
		end
		let(:simple_object) {
			create(:simple_object_with_friends_and_parent)
		}
		context 'when shrunk' do 
			subject { 
				convert_to_json(ApiNew::ApiController.render('api_new/simple_objects/show', 
					assigns: {simple_object:simple_object,
					__expand: Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new
				}))
			}
			
			it {
				is_expected.to include("parent" => simple_object.parent.houid)
			}
		end

		context 'when expanded' do 
			subject { 
				convert_to_json(ApiNew::ApiController.render('api_new/simple_objects/show', 
					assigns: {
						simple_object:simple_object,
						__expand: Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('parent')
				}))
			}
			
			it {
				is_expected.to include("parent" => {
					'id' => simple_object.parent.houid,
					'parent' => simple_object.parent.parent.houid,
					'friends' => [],
					'object' => 'simple_object',
					'nonprofit' => nil
				})
			}
		end

		context 'when expanded twice' do 
			subject { 
				convert_to_json(ApiNew::ApiController.render('api_new/simple_objects/show', 
					assigns: {
						simple_object:simple_object,
						__expand: Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('parent.parent')
				}))
			}
			
			it {
				is_expected.to include("parent" => {
					'id' => simple_object.parent.houid,
					'parent' => {
						'id' => simple_object.parent.parent.houid,
						'parent' => nil,
						'object' => 'simple_object',
						'friends' => [],
						'nonprofit' => nil
					},
					'friends' => [],
					'object' => 'simple_object',
					'nonprofit' => nil
				})
			}
		end
		
	end

	describe '#handle_array_expansion/#handle_item_expansion' do
		def convert_to_json(tree)
			JSON::parse(tree)
		end
		let(:simple_object) {
			create(:simple_object_with_friends_and_parent)
		}
		context 'when shrunk' do 
			subject { 
				convert_to_json(ApiNew::ApiController.render('api_new/simple_objects/show', 
					assigns: {simple_object:simple_object,
					__expand: Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new
				}))
			}
			
			it {
				is_expected.to include("friends" => 
						match_array(simple_object.friends.pluck(:houid)))
			}
		end

		context 'when expanded' do 
			subject { 
				convert_to_json(ApiNew::ApiController.render('api_new/simple_objects/show', 
					assigns: {
						simple_object:simple_object,
						__expand: Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('friends')
				}))
			}
			
			it {
				is_expected.to include("friends" => 
						match_array([
							{
								'id' => simple_object.friends.first.houid,
								'object' => 'simple_object',
								'friends'=> [],
								'parent' => nil,
								'nonprofit' => nil
							},
							{
								'id' => simple_object.friends.last.houid,
								'object' => 'simple_object',
								'friends'=> [],
								'parent' => simple_object.friends.last.parent.houid,
								'nonprofit' => nil
							},
						]	
				))
			}
		end

		context 'when expanded twice' do 
			subject { 
				convert_to_json(ApiNew::ApiController.render('api_new/simple_objects/show', 
					assigns: {
						simple_object:simple_object,
						__expand: Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('friends.parent')
				}))
			}
			
			it {
				is_expected.to include("friends" => 
						match_array([
							{
								'id' => simple_object.friends.first.houid,
								'object' => 'simple_object',
								'friends'=> [],
								'parent' => nil,
								'nonprofit' => nil
							},
							{
								'id' => simple_object.friends.last.houid,
								'object' => 'simple_object',
								'friends'=> [],
								'parent' => {
									'id' => simple_object.friends.last.parent.houid,
									'object' => 'simple_object',
									'friends' => [],
									'parent' => nil,
									'nonprofit' => nil
								},
								'nonprofit' => nil
									
							},
						]	
				))
			}
		end
	end


	describe '::ExpansionRequest' do 
		def convert_to_json(expansion_request)
			JSON::parse(JSON::dump(expansion_request.path_tree))
		end
		context 'can be empty' do
			subject{ convert_to_json(Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new)}

			it {
				is_expected.to match_json()
			}
		end

		context 'can have a single item' do
			subject{ convert_to_json(Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('supporter'))}

			it {
				is_expected.to match_json(supporter: {})
			}
		end

		context 'can have a multiple items at multiple levels' do
			subject{ convert_to_json(Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('supporter', 'transaction.subtransaction'))}

			it {
				is_expected.to match_json(supporter: {}, transaction: {subtransaction: {}})
			}
		end

		context 'can safely have shorter paths that dont overload longer paths' do
			subject{ convert_to_json(Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('supporter', 'transaction.subtransaction', 'transaction'))}

			it {
				is_expected.to match_json(supporter: {}, transaction: {subtransaction: {}})
			}
		end

		describe "#[]" do 
			context 'returns an empty ExpansionRequest when no child with the given path exists' do
				subject{ convert_to_json(Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('supporter')['transaction'])}

				it {
					is_expected.to match_json
				}
			end

			context 'returns a child\'s ExpansionRequest' do
				subject{ convert_to_json(Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('supporter', 'transaction.subtransaction')['transaction'])}

				it {
					is_expected.to match_json({subtransaction: {}})
				}

			end

			context 'keeps returning empty ExpansionRequests when none are available' do
				subject{ convert_to_json(Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('transaction.subtransaction')['transaction']['subtransaction']['payments']['charge'])}

				it {
					is_expected.to match_json({})
				}

			end
		end

		describe '#expand?' do
			subject { Controllers::ApiNew::JbuilderExpansions::ExpansionRequest.new('supporter', 'transaction.subtransaction', 'transaction') }
				
			it 'returns false when a path should not be expanded' do 
				is_expected.to_not be_expand 'nonprofit'
			end

			it 'returns true when a path should be expanded' do 
				is_expected.to be_expand 'supporter'
			end

		end
	end
end
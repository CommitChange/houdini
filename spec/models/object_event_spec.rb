require 'rails_helper'

RSpec.describe ObjectEvent, type: :model do
  it_behaves_like 'an houidable entity', :evt

  around(:each) {|ex|
    Timecop.freeze(Time.new(2020, 5, 4)) do 
      ex.run
    end
  }
  let(:simple_object_with_parent) { create(:simple_object_with_parent)}

  let(:evt) {
    simple_object_with_parent.publish_created
    
  }

  describe 'after_save is accurate' do
    subject(:event) { evt}
    it {
      is_expected.to be_persisted
    }

    it {
      is_expected.to have_attributes(
        houid: match_houid("evt"),
        event_type: 'simple_object.created',
        event_entity: simple_object_with_parent,
        created: Time.new(2020, 5, 4)
      )
    }

    describe 'json' do
      subject(:json) { event.object_json}
      it {
        is_expected.to include(
          'id' => match_houid("evt"),
          'type' => 'simple_object.created',
          'object' => "object_event",
          'created' => Time.new(2020, 5, 4).to_i
        )
      }

      describe '-> data' do 
        subject(:data) {json['data']}
        describe '-> object' do 
          subject(:object) { data['object']}

          it {
            is_expected.to include(
              'id' => simple_object_with_parent.houid,
              'object' => "simple_object",
              'friends' => all(be_an(Integer)),
              'parent' => be_a(Hash)
            )
          }
        end
      end

    end
  end

  describe "::Query" do
    let(:nonprofit) { simple_object_with_parent.nonprofit}
    
    

    describe '.query' do
      before(:each) { 
        simple_object_with_parent.publish_created
        simple_object_with_parent.publish_updated
      }

      context 'empty query' do
        subject(:event_objects) { nonprofit.associated_object_events.query}

        it {
          expect(event_objects.count).to eq 2
        }
      end

      context 'with event_entity' do
        context 'and entity doesnt exist' do 
          subject(:event_objects) { nonprofit.associated_object_events.query(event_entity: 'fake_entity')}
          it {
            is_expected.to be_none
          }
        end

        context 'and entity does exist' do 
          subject(:event_objects) { nonprofit.associated_object_events.query(event_entity: simple_object_with_parent.houid)}
          it {
            expect(event_objects.count).to eq 2
          }
        end
        
      end

      context 'with event_types' do
        context 'and event_types doesnt exist' do 
          subject(:event_objects) { nonprofit.associated_object_events.query(event_types: ['soennoet.come'])}
          it {
            is_expected.to be_none
          }
        end

        context 'and event_types does exist' do 
          subject(:event_objects) { nonprofit.associated_object_events.query(event_types: ['simple_object.created'])}
          it {
            expect(event_objects.count).to eq 1
          }
        end
        
      end

    end
  end
end

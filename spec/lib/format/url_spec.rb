# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require_relative '../../../app/legacy_lib/format/url'
describe Format::Url do

	describe '.concat' do
		let(:event_url) {"al/birmingham/hand-in-paw/events/picasso-pets"}
		let(:root_url) {"http://localhost:8080/"}
		let(:formatted_url) {"http://localhost:8080/al/birmingham/hand-in-paw/events/picasso-pets"}

		it "removes extra whacks from the url" do
			# and helps prevent broken links in emails
			expect(Format::Url.concat(root_url, event_url)).to eq(formatted_url)
		end
	end
end

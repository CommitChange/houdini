# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

RSpec.describe StaticController, type: :controller do
  describe "#ccs" do
    describe "#ccs_method" do
      context "when local_tar_gz" do
        before do
          Settings.add_source!({ccs: { ccs_method: "local_tar_gz" }})
          Settings.reload!
        end

        it "fails on git archive" do
          expect(Kernel).to receive(:system).and_return(false)
          get("ccs")
          expect(response.status).to eq 500
        end
      end

      context "when github" do
        before do
          Settings.add_source!({ccs: {
            ccs_method: "github",
            options: {
              account: "account",
              repo: "repo"
            } }
          })
          Settings.reload!
        end

        it "setup github" do
          expect(File).to receive(:read).with("#{Rails.root}/CCS_HASH").and_return("hash\n")
          get("ccs")
          expect(response).to redirect_to "https://github.com/account/repo/tree/hash"
        end
      end
    end
  end
end

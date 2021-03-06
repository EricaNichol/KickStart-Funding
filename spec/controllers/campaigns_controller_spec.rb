require 'rails_helper'

RSpec.describe CampaignsController, type: :controller do
  let(:user)     { create(:user)                 }
  let(:user_1)   { create(:user)                 }
  let(:campaign) { create(:campaign, user: user) }

  describe "#new" do
    context "user not signed in" do
      it "redirect to login page" do
        get :new
        expect(response).to redirect_to new_session_path
      end
    end
    context "user signed in" do
      before do
        login(user)
      end

      it "renders the new campaign template" do
        get :new
        expect(response).to render_template(:new)
      end

      it "instantiates a new campaign object" do
        get :new
        expect(assigns(:campaign)).to be_a_new(Campaign)
      end
    end
  end

  describe "#create" do
    context "with user not signed in" do
      it "redirects to sign in page" do
        post :create
        expect(response).to redirect_to new_session_path
      end
    end

    context "with user signed in" do
      before { login(user) }

      context "with valid parameters" do

        def valid_request
          post :create, campaign: attributes_for(:campaign)
        end

        it "creates a campaign in the database" do
          expect { valid_request }.to change { Campaign.count }.by(1)
        end

        it "redirects to campaign show page" do
          valid_request
          expect(response).to redirect_to campaign_path(Campaign.last)
        end

        it "sets a flash message" do
          valid_request
          expect(flash[:notice]).to be
        end

        it "associates the created campaign with the logged in user" do
          valid_request
          expect(Campaign.last.user).to eq(user)
        end
      end

      context "with invalid parameters" do
        def invalid_request
          post :create, campaign: {title: nil}
        end

        it "doesn't create a record in the database" do
          expect { invalid_request }.to change { Campaign.count }.by(0)
        end

        it "renders the new template" do
          invalid_request
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe "#show" do
    before { get :show, id: campaign.id }

    it "instantiates a campaign variable with the Campaign whose id is passed" do
      expect(assigns(:campaign)).to eq(campaign)
    end

    it "it renders the show template" do
      expect(response).to render_template(:show)
    end
  end

  describe "#index" do
    let(:campaign_1) { create(:campaign) }

    it "assigns an instance variable @campaigns to all created campaigns" do
      # we're calling campaign and campaign_1 in order for them to be created
      # in the database before we make the request
      campaign
      campaign_1
      get :index
      expect(assigns(:campaigns)).to eq([campaign, campaign_1])
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "#edit" do
    context "with signed in user" do
      context "with authorized user signed in" do
        before { login user }
        it "renders the edit template" do
          get :edit, id: campaign.id
          expect(response).to render_template :edit
        end
        it "instantiates an instance variable with the campaign whose is is passed" do
          get :edit, id: campaign.id
          expect(assigns(:campaign)).to eq(campaign)
        end
      end
      context "with unauthorized user signed in" do
        before { login user_1 }
        it "redirects to root path" do
          get :edit, id: campaign.id
          expect(response).to redirect_to root_path
        end
        it "sets a flash message" do
          get :edit, id: campaign.id
          expect(flash[:alert]).to be
        end
      end
    end
    context "with no signed in user" do
      it "redirects to new session path" do
        get :edit, id: campaign.id
        expect(response).to redirect_to new_session_path
      end
    end
  end

  describe "#update" do
    context "with no signed in user" do
      it "redirects to new session path" do
        patch :update, id: campaign.id
        expect(response).to(redirect_to(new_session_path))
      end
    end
    context "with signed in user" do
      context "user is unauthorized" do
        before { login(user_1) }
        it "redirects to the home page" do
          patch :update, id: campaign.id
          expect(response).to redirect_to root_path
        end
      end
      context "user is authorized" do
        before { login(user) }
        def valid_attributes(new_attributes = {})
          attributes_for(:campaign).merge(new_attributes)
        end
        context "with valid attributes" do
          it "updates the campaign record with new attributes" do
            new_goal = campaign.goal + 1
            patch :update, id: campaign.id, campaign: valid_attributes(goal: new_goal)
            campaign.reload
            expect(campaign.goal).to eq(new_goal)
          end
          it "redirect to campaign show page" do
            new_goal = campaign.goal + 1
            patch :update, id: campaign.id, campaign: valid_attributes(goal: new_goal)
            campaign.reload
            expect(response).to redirect_to(campaign_path(campaign))
          end
        end
        context "with invalid attributes" do
          def invalid_request
            patch(:update, {id: campaign.id, campaign: valid_attributes({title: nil})})
          end
          it "doesn't update the campaign with the new attributes" do
            expect { invalid_request }.not_to change { campaign.reload.title }
          end

          it "renders the edit template" do
            invalid_request
            expect(response).to render_template(:edit)
          end
        end
      end
    end
  end

  describe "#destroy" do
    context "with no signed in user" do
      it "redirects to new session path" do
        delete :destroy, id: campaign.id
        expect(response).to redirect_to new_session_path
      end
    end
    context "with signed in user" do
      context "user is authorized" do
        before { login(user) }
        let!(:campaign) { create(:campaign, user: user) }
        it "deletes a campaign from the database" do
          before_count = Campaign.count
          delete :destroy, id: campaign.id
          after_count = Campaign.count
          expect(before_count - after_count).to eq(1)
        end
        it "redirect to campaigns index page" do
          delete :destroy, id: campaign.id
          expect(response).to redirect_to campaigns_path
        end
      end
      context "user is unauthorized" do
        before { login(user_1) }

        it "redirects to home page" do
          delete :destroy, id: campaign.id
          expect(response).to redirect_to root_path
        end
      end
    end
  end
end

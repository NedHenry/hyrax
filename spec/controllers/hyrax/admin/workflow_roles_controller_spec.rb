RSpec.describe Hyrax::Admin::WorkflowRolesController do
  describe "#get" do
    context "when you have permission" do
      before do
        allow(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
      end

      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).with('Home', root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Administration', dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Workflow Roles', admin_workflow_roles_path(locale: 'en'))
        get :index
        expect(response).to be_success
        expect(assigns[:presenter]).to be_kind_of Hyrax::Admin::WorkflowRolesPresenter
        expect(response).to render_template('hyrax/dashboard')
      end
    end

    context "when they don't have permission" do
      it "throws a CanCan error" do
        get :index
        expect(response).to redirect_to main_app.new_user_session_path(locale: 'en')
      end
    end
  end
end

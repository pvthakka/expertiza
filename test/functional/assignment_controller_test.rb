require File.dirname(__FILE__) + '/../test_helper'
require 'assignment_controller'

# Re-raise errors caught by the controller.
class AssignmentController; def rescue_action(e) raise e end; end

class AssignmentControllerTest < ActionController::TestCase
  # use dynamic fixtures to populate users table
  # for the use of testing
  fixtures :users
  fixtures :assignments
  fixtures :questionnaires
  fixtures :courses
  set_fixture_class :system_settings => 'SystemSettings'
  fixtures :system_settings
  fixtures :content_pages
  @settings = SystemSettings.find(:first)

  def setup
    @controller = AssignmentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.session[:user] = User.find(users(:instructor3).id )
    roleid = User.find(users(:instructor3).id).role_id
    Role.rebuild_cache

    Role.find(roleid).cache[:credentials]
    @request.session[:credentials] = Role.find(roleid).cache[:credentials]
    # Work around a bug that causes session[:credentials] to become a YAML Object
    @request.session[:credentials] = nil if @request.session[:credentials].is_a? YAML::Object
    @settings = SystemSettings.find(:first)
    AuthController.set_current_role(roleid,@request.session)
    #   @request.session[:user] = User.find_by_name("suadmin")
  end

  # Test Case 1101
  def test_new
    questionnaire_id = Questionnaire.first.id
    instructorid = Instructor.first.id
    courseid = Course.first.id
    # create a new assignment
    assignment = Assignment.new( :name => "2_valid_test",
      :course_id           => 1,
      :directory_path      => "2_valid_test",
      :review_questionnaire_id    => questionnaire_id,
      :review_of_review_questionnaire_id => questionnaire_id,
      :author_feedback_questionnaire_id  => questionnaire_id,
      :instructor_id => instructorid,
      :course_id => courseid,
      :wiki_type_id => 1
    )

    #p flash[:notice].to_s
    assert assignment.save
  end

    # Test Case 1101-A
  def test_copy
    # copy an assignment

    @assignment = Assignment.first
    assignment_id = @assignment.id
    assignment_name = @assignment.name
    post :copy, :id => assignment_id
    assert_response :redirect
    assert Assignment.find( :all, :conditions => ['name = ?', "Copy of " + assignment_name] )
    copied = Assignment.find( :first, :conditions => ['name = ?', "Copy of " + assignment_name] )
    dir = copied.directory_path
    assert Dir[dir].empty?
  end

# Edited wrt E702
# Test Case 1101B
# This test creates a new assignment which is a microtask and submits it.
  def test_new_microtask
    #@assignment = assignments(:Assignment_Microtask1)
    questionnaire_id = questionnaires(:questionnaire1).id
    instructorid = users(:instructor1).id
    courseid = courses(:course_object_oriented).id,
    number_of_topics = SignUpTopic.count
    # create a new assignment
    post :new, :assignment => { :name => "Assignment_Microtask1",
      :directory_path      => "CSC517_instructor1/Assignment_Microtask1",
      :submitter_count => 0,
      :course_id => courseid,
      :instructor_id => instructorid,
      :num_reviews => 1,
      :num_review_of_reviews => 0,
      :num_review_of_reviewers => 0,
      :review_questionnaire_id => questionnaire_id,
      :reviews_visible_to_all => 0,
      :require_signup => 0,
      :num_reviewers => 3,
      :team_assignment => 0,
      :team_count => 1,
      :microtask => true }

      assert_response 200
      assert Assignment.find(:all, :conditions => "name = 'Assignment_Microtask1'")

  end



  # Test Case 1102
  # illegally edit an assignment, name the existing
  # assignment with an invalid name or another existing
  # assignment name, should not be allowed to changed DB data
  def test_illegal_edit_assignment

    id = Assignment.first.id
    @assignment = Assignment.first
    original_assignment_name = @assignment.name
    number_of_assignment = Assignment.count
    # It will raise an error while execute render method in controller
    # Because the goldberg variables didn't been initialized  in the test framework
    assert_raise (ActionView::TemplateError){
      post :update, :id => id, :assignment=> { :name => '',
          :directory_path => "admin/test1",
          :review_questionnaire_id => 1,
          :review_of_review_questionnaire_id => 1,
        },
        :due_date => {  "1" , { :resubmission_allowed_id =>1 ,
          :submission_allowed_id =>3,
          :review_of_review_allowed_id =>1,
          :review_allowed_id =>1,
          :due_at =>"2007-07-10 15:00:00",
          :rereview_allowed_id =>1
        }
      }
    }
    assert_template 'assignment/edit'
    assert_equal original_assignment_name, Assignment.first.name
  end

  # 1201 Delete a assignment
  def test_delete_assignment

    number_of_assignment = Assignment.count
    number_of_duedate = DueDate.count
    id = Assignment.first(:conditions => {:instructor_id => users(:instructor3).id}).id
    post :delete, :id => id
    assert_redirected_to :controller => 'tree_display', :action => 'list'
    assert_equal number_of_assignment-1, Assignment.count
    assert_raise(ActiveRecord::RecordNotFound){ Assignment.find(id) }

  end
end



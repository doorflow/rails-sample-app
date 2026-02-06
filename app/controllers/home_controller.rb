# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @members_count = CrmMember.count
    @linked_count = CrmMember.linked.count
    @teams_count = CrmTeam.count
    @connection_status = doorflow_status
  end
end

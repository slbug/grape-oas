# frozen_string_literal: true

class SampleAPI < Grape::API
  format :json

  namespace :books do
    desc "Get a book"
    params do
      requires :id, type: Integer, desc: "Book ID"
    end
    get ":id" do
      { id: params[:id], title: "GOS" }
    end
  end
end

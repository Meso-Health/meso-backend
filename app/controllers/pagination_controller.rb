class PaginationController < ApplicationController
  DEFAULT_PAGE_SIZE = 25
  MAX_PAGE_SIZE = 1000
  MAX_CSV_EXPORT_SIZE = 10_000
  SORT_DESCENDING_CHARACTER = '-'
  DEFAULT_SORT_FIELD = 'created_at'
  DEFAULT_SORT_DIRECTION = 'asc'
  SORTABLE_FIELDS = %w[created_at]

  before_action :parse_pagination_params!, only: :index

  protected

  def parse_pagination_params!
    if request.format.csv?
      @limit = MAX_CSV_EXPORT_SIZE
    else
      @limit = params[:limit] ? Integer(params[:limit]) : self.class::DEFAULT_PAGE_SIZE
      unless (1..self.class::MAX_PAGE_SIZE).cover?(@limit)
        ExceptionsApp.for(:bad_request).render(self)
        return
      end
    end

    @sort = params[:sort]
    if @sort.nil?
      @sort_direction = self.class::DEFAULT_SORT_DIRECTION
      @sort_field = self.class::DEFAULT_SORT_FIELD
    elsif @sort.starts_with?(SORT_DESCENDING_CHARACTER)
      @sort_direction = 'desc'
      @sort_field = @sort[1..-1]
    else
      @sort_direction = 'asc'
      @sort_field = @sort
    end
    unless self.class::SORTABLE_FIELDS.include?(@sort_field)
      ExceptionsApp.for(:bad_request).render(self)
      return
    end

    if params[:starting_after] && params[:ending_before]
      ExceptionsApp.for(:bad_request).render(self)
    elsif params[:starting_after]
      @starting_after_cursor = Base64.decode64(params[:starting_after])
    elsif params[:ending_before]
      @ending_before_cursor = Base64.decode64(params[:ending_before])
    end
  rescue TypeError, ArgumentError
    ExceptionsApp.for(:bad_request).render(self)
  end
end

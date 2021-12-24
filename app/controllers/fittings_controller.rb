# frozen_string_literal: true

class FittingsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_fitting, only: %i[show edit update destroy inventory_chart_data]

  def index
    @pagy, @fittings = pagy(Fitting.kept.where(owner_id: main_alliance_id).order(:name))

    if turbo_frame_request?
      render partial: 'fittings', locals: { fittings: @fittings, paginator: @pagy }
    else
      render :index
    end
  end

  def show
    @fitting = Fitting.find(params[:id])
  end

  def new
    @fitting = Fitting.new
  end

  def create; end

  def edit; end

  def update
    if @fitting.update(fitting_params)
      flash[:success] = 'Fitting settings updated sucessfully.'
      redirect_to fitting_path(@fitting)
    else
      render :edit
    end
  end

  def destroy; end

  def inventory_chart_data
    raw = {
      price: @fitting.contracts_sold(:month).group_by_day(:completed_at).average(:price),
      volume: @fitting.contracts_sold(:month).group_by_day(:completed_at).count
    }

    data = raw[:price].each_with_object([]) do |(date, price), a|
      a << { date: date, price: price.to_f || 0.0, volume: raw[:volume][date].to_i }
    end

    render json: data
  end

  def stock_control_data
  end

  private

  def find_fitting
    @fitting = authorize(Fitting.find(params[:id]))
  end

  def fitting_params
    params.require(:fitting).permit(:name, :contract_match_threshold, :killmail_match_threshold, :pinned, :safety_stock)
  end
end

class ErrorLogController < ApplicationController
  allow :all=>[:form,:index]
  access_control :include=>[:form,:index]
  def index
    redirect_to :action=>"form",:all=>params
  end
  
  def form
    @errors={}
    @object={}
    if request.post?
      data=params[:object]
      fields={:steps=>t(:"error log.description")}
      [:steps,:url].each{|key|
        @object[key]=data[key]
      }
      fields.each{|key,value|
        unless data[key] && data[key].size>0
          @errors[value]=[" #{t(:"ActiveRecord.errors.empty")}",nil]
        end
      }
      if @errors.empty?
        body_data={
          :header=>"#{Admin::Configuration.get_value_by_name("default_title")} #{t(:"error log.title")}",
          :body=>[]
        }
        body_data[:body]<<{:title=>t(:"error log.description"),:value=>data[:steps]}
        body_data[:body]<<{:title=>t(:"error log.system url"),:value=>data[:url]}
        body_data[:body]<<{:title=>t(:"error log.sender"),:value=>data[:submitter]}
        email_sent("bugs@ithouse.lv",body_data[:header],body_data) 
      end
    end
    if @errors.empty? && request.post?
      redirect_to :controller=>Admin::Configuration.get_value_by_name("start_page")
    else
      render :layout=>"cms/simple"
    end
  end
  
  private
  
  def email_sent (email,title,data)
    RequestMailer::deliver_mail(email,"#{title}",data)
  end
end

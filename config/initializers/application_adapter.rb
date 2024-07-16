class ApplicationAdapter < ActiveModelSerializers::Adapter::JsonApi
  def success_document
    super[:meta] ? super : super.merge(meta: {})
  end
end

module ErrorSerializer
  def self.serialize(object)
    object.errors.map do |error|
      {
        code: 'unprocessable_entity',
        status: '422',
        title: 'Validation Error',
        detail: "#{error.attribute.capitalize} #{error.message}",
        source: { pointer: "/data/attributes/#{error.attribute}" },
        meta: {
          attribute: error.attribute,
          message: error.message,
          code: error.type
        }
      }
    end.flatten
  end
end

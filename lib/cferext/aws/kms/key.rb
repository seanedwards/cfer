Cfer::Core::Resource.extend_resource "AWS::KMS::Key" do
  def key_policy(doc = nil, &block)
    doc = CferExt::AWS::IAM.generate_policy(&block) if doc == nil
    properties :KeyPolicy => doc
  end
end


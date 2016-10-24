require 'docile'

Cfer::Core::Resource.extend_resource "AWS::Route53::RecordSetGroup" do
  %w{a aaaa cname mx ns ptr soa spf srv txt}.each do |type|
    define_method type.to_sym do |name, records, options = {}|
      self[:Properties][:RecordSets] ||= []
      self[:Properties][:RecordSets] << options.merge(Type: type.upcase, Name: name, ResourceRecords: [ records ].flatten)
    end
  end
end


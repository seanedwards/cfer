Cfer::Core::Resource.extend_resource "AWS::AutoScaling::AutoScalingGroup" do
  def desired_size(size)
    desired_capacity size
  end
end


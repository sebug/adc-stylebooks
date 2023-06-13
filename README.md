# ADC Stylebooks
Trying out some of the infrastructure-as-code features for Citrix ADC.

*Note that it is completely silly to actually create an infrastructure in the cloud like that* - the Azure Builtins for app hosting do a much better job. The reason I'm doing it is to see how this would work in an on-prem environment.

After all I'm going to be setting up the stuff declaratively, this stuff's expensive.

## Set up Azure resources
Create a resource group ADCTestRG .

For the main.bicep we inspire ourselves by https://docs.netscaler.com/en-us/citrix-adc/current-release/deploying-vpx/deploy-vpx-on-azure/configure-vpx-standalone-arm.html

or this one, rather: https://docs.netscaler.com/en-us/citrix-application-delivery-management-service/hybrid-multi-cloud-deployments/provisioning-vpx-azure.html

From the Azure cloud shell (as to not have any credentials locally):

    git clone https://github.com/sebug/adc-stylebooks.git
    cd adc-stylebooks
    az deployment group create -f ./main.bicep -g ADCTestRG

To connect to the VMs and to test out hosting I added a Bastion instance. This should no longer be necessary
in the final setup, but in the meantime it's a good way to play around.

Some VM post-configuration will simply be done by a PowerShell script - I'd like to do better, but at the
moment that seems to be the easiest (plus I'm gonna delete those machines often anyway).

For ADC, I started by enable automatic provisioning of Citrix ADC 13.1 (Express) and enabled that on my subscription. Took the template.json and tried to integrate it in my main.bicep

I enabled the management ports on the management IP and then connected to said IP using HTTP.

If it is not automatically selected (it should be), set the subnet IP as 22.22.2.6 (or whatever was assigned to the isVMNic interface of your ADC VM).

Add a virtual server pointing to the private IP address of the adcVMNic, name mainvs.

Go to services. Add the two VM private IPs as services first-vm and second-vm.

Add a service group mainsg

Add the two servers as service group members.

Go back to the virtual server, edit mainvs.

Add the mainsg service group as binding.

Now jot down the public IP address of the adcVMNic and connect to it via http on the port. See that it switches between the content of server 1 and 2.








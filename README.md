# ADC Stylebooks
Trying out some of the infrastructure-as-code features for Citrix ADC.

*Note that it is completely silly to actually create an infrastructure in the cloud like that* - the Azure Builtins for app hosting do a much better job. The reason I'm doing it is to see how this would work in an on-prem environment.

After all I'm going to be setting up the stuff declaratively, this stuff's expensive.

## Set up Azure resources
Create a resource group ADCTestRG .

From the Azure cloud shell (as to not have any credentials locally):

    git clone https://github.com/sebug/adc-stylebooks.git
    cd adc-stylebooks
    az deployment group create -f ./main.bicep -g ADCTestRG

To connect to the VMs and to test out hosting I added a Bastion instance. This should no longer be necessary
in the final setup, but in the meantime it's a good way to play around.

Some VM post-configuration will simply be done by a PowerShell script - I'd like to do better, but at the
moment that seems to be the easiest (plus I'm gonna delete those machines often anyway).




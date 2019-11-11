*** Settings ***
Documentation            Update firmware on a target Host via Redifsh.

# Test Parameters:
# IMAGE_FILE_PATH        The path to the Host image file.
#
# Firmware update states:
#     Enabled            Image is installed and either functional or active.
#     Disabled           Image installation failed or ready for activation.
#     Updating           Image installation currently in progress.

Resource                 ../../lib/resource.robot
Resource                 ../../lib/bmc_redfish_resource.robot
Resource                 ../../lib/boot_utils.robot
Resource                 ../../lib/openbmc_ffdc.robot
Resource                 ../../lib/common_utils.robot
Resource                 ../../lib/code_update_utils.robot
Resource                 ../../lib/dump_utils.robot
Resource                 ../../lib/logging_utils.robot
Resource                 ../../lib/redfish_code_update_utils.robot
Library                  ../../lib/gen_robot_valid.py
Library                  ../../lib/tftp_update_utils.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

Force Tags               Host_Code_Update

*** Test Cases ***

Redfish Code Update With ApplyTime OnReset
    [Documentation]  Update the firmaware image with ApplyTime of OnReset.
    [Tags]  Redfish_Code_Update_With_ApplyTime_OnReset
    [Template]  Redfish Update Firmware

    # policy
    OnReset  ${IMAGE_HOST_FILE_PATH_0}


Redfish Code Update With ApplyTime Immediate
    [Documentation]  Update the firmaware image with ApplyTime of Immediate.
    [Tags]  Redfish_Code_Update_With_ApplyTime_Immediate
    [Template]  Redfish Update Firmware

    # policy
    Immediate  ${IMAGE_HOST_FILE_PATH_1}


BMC Reboot When PNOR Update Goes On
    [Documentation]  Trigger PNOR update and do BMC reboot.
    [Tags]  BMC_Reboot_When_PNOR_Update_Goes_On

    ${bios_version_before}=  Redfish.Get Attribute  /redfish/v1/Systems/system/  BiosVersion
    Redfish Firmware Update And Do BMC Reboot
    ${bios_version_after}=  Redfish.Get Attribute  /redfish/v1/Systems/system/  BiosVersion
    Valid Value  bios_version_after  ['${bios_version_before}']


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Valid File Path  IMAGE_HOST_FILE_PATH_0
    Valid File Path  IMAGE_HOST_FILE_PATH_1
    Redfish.Login
    Delete All BMC Dump
    Redfish Purge Event Log
    Redfish Power On  stack_mode=skip


Redfish Update Firmware
    [Documentation]  Update the BMC firmware via redfish interface.
    [Arguments]  ${apply_time}  ${image_file_path}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    Redfish.Login

    # Redfish Upload Image And Check Progress State  ${apply_time}
    # Poweron Host And Verify Host Image  ${apply_time}
    Redfish Upload Image  /redfish/v1/UpdateService  ${image_file_path}
    Sleep  5 mins

    Wait State  os_running_match_state  15 mins
    Redfish.Login
    Redfish Verify Host Version  ${image_file_path}

Redfish Firmware Update And Do BMC Reboot
    [Documentation]  Update the firmware via redfish interface and do BMC reboot.

    Set ApplyTime  policy="Immediate"
    Redfish Upload Image  ${REDFISH_BASE_URI}UpdateService  ${IMAGE_FILE_PATH}
    ${image_id}=  Get Latest Image ID
    Wait Until Keyword Succeeds  1 min  10 sec
    ...  Check Image Update Progress State  match_state='Updating'  image_id=${image_id}

    # BMC reboot while PNOR update is in progress.
    Redfish OBMC Reboot (off)


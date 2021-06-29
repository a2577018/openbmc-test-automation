*** Settings ***

Documentation  Test OpenBMC GUI "LDAP" sub-menu of "Access control".

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_ldap_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_ldap_heading}                   //h1[text()="LDAP"]
${xpath_enable_ldap_checkbox}           //*[@data-test-id='ldap-checkbox-ldapAuthenticationEnabled']
${xpath_secure_ldap_checkbox}           //*[@data-test-id='ldap-checkbox-secureLdapEnabled']
${xpath_service_radio_button}           //*[@data-test-id="ldap-radio-activeDirectoryEnabled"]
${xpath_add_role_group_button}          //button[contains(text(),'Add role group')]
${xpath_ldap_url}                       //*[@data-test-id='ldap-input-serverUri']
${xpath_ldap_bind_dn}                   //*[@data-test-id='ldap-input-bindDn']
${xpath_ldap_password}                  //*[@id='bind-password']
${xpath_ldap_base_dn}                   //*[@data-test-id='ldap-input-baseDn']
${xpath_ldap_save_settings}             //*[@data-test-id='ldap-button-saveSettings']
${xpath_select_refresh_button}          //*[text()[contains(.,"Refresh")]]
${xpath_add_group_name}                 //*[@id="role-group-name"]
${xpath_add_group_Privilege}            //*[@id="privilege"]
${xpath_add_privilege_button}           //button[text()=" Add "]
${xpath_delete_group_button}            //*[@title="Delete"]
${xpath_delete_button}                  //button[text()="Delete"]


${incorrect_ip}     1.2.3.4

*** Test Cases ***

Verify Navigation To LDAP Page
    [Documentation]  Verify navigation to LDAP page.
    [Tags]  Verify_Navigation_To_LDAP_Page

    Page Should Contain Element  ${xpath_ldap_heading}


Verify Existence Of All Sections In LDAP Page
    [Documentation]  Verify existence of all sections in LDAP page.
    [Tags]  Verify_Existence_Of_All_Sections_In_LDAP_Page

    Page Should Contain  Settings
    Page Should Contain  Role groups


Verify Existence Of All Buttons In LDAP Page
    [Documentation]  Verify existence of all buttons in LDAP page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_LDAP_Page

    # Buttons under settings section.
    Page Should Contain Element  ${xpath_service_radio_button}
    Page Should Contain Element  ${xpath_save_settings_button}

    # Buttons under role groups section.
    Page Should Contain Element  ${xpath_add_role_group_button}


Verify Existence Of All Checkboxes In LDAP Page
    [Documentation]  Verify existence of all checkboxes in LDAP page.
    [Tags]  Verify_Existence_Of_All_Checkboxes_In_LDAP_Page

    # Checkboxes under settings section.
    Page Should Contain Element  ${xpath_enable_ldap_checkbox}
    Page Should Contain Element  ${xpath_secure_ldap_checkbox}


Verify LDAP Configurations Editable
    [Documentation]  Verify LDAP configurations are editable.
    [Tags]  Verify_LDAP_Configurations_Editable

    Create LDAP Configuration  ${LDAP_SERVER_URI}  ${LDAP_TYPE}  ${LDAP_BIND_DN}
    ...  ${LDAP_BIND_DN_PASSWORD}  ${LDAP_BASE_DN}
    Wait Until Page Contains Element  ${xpath_ldap_url}
    Textfield Value Should Be  ${xpath_ldap_url}  ${LDAP_SERVER_URI}
    Textfield Value Should Be  ${xpath_ldap_bind_dn}  ${LDAP_BIND_DN}
    Textfield Value Should Be  ${xpath_ldap_password}  ${empty}
    Textfield Value Should Be  ${xpath_ldap_base_dn}  ${LDAP_BASE_DN}


Verify Create LDAP Configuration
    [Documentation]  Verify created LDAP configuration.
    [Tags]  Verify_Created_LDAP_Configuration
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    Create LDAP Configuration
    Get LDAP Configuration  ${LDAP_TYPE}
    Redfish.Logout
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}


Verify LDAP Config Update With Incorrect LDAP IP Address
    [Documentation]  Verify that LDAP login fails with incorrect LDAP IP Address.
    [Tags]  Verify_LDAP_Config_Update_With_Incorrect_LDAP_IP_Address
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    Create LDAP Configuration  ${incorrect_ip}   ${LDAP_TYPE}  ${LDAP_BIND_DN}
    ...  ${LDAP_BIND_DN_PASSWORD}  ${LDAP_BASE_DN}  ${LDAP_MODE}

    Get LDAP Configuration  ${LDAP_TYPE}
    Redfish.Logout

    ${resp}=  Run Keyword And Return Status
    ...  Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${False}
    ...  msg=LDAP user was able to login though the incorrect LDAP IP Address.


Verify LDAP Service Disable
    [Documentation]  Verify that LDAP user cannot login when LDAP service is disabled.
    [Tags]  Verify_LDAP_Service_Disable
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    ${status}=  Run Keyword And Return Status
    ...  Checkbox Should Be Selected  ${xpath_enable_ldap_checkbox}

    Run Keyword If  ${status} == ${True}
    ...  Click Element At Coordinates  ${xpath_enable_ldap_checkbox}  0  0

    Checkbox Should Not Be Selected  ${xpath_enable_ldap_checkbox}
    Click Element  ${xpath_ldap_save_settings}
    Wait Until Page Contains  Successfully saved Open LDAP settings
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains Element  ${xpath_ldap_heading}
    Redfish.Logout

    ${resp}=  Run Keyword And Return Status
    ...  Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${False}
    ...  msg=LDAP user was able to login even though the LDAP service was disabled.


Verify LDAP User With Admin Privilege
    [Documentation]  Verify that LDAP user with administrator privilege is able to do BMC reboot.
    [Tags]  Verify_LDAP_User_With_Admin_Privilege
    [Teardown]  Run Keywords  Redfish.Login  AND  Delete LDAP Role Group  ${GROUP_NAME}

    Update LDAP Configuration with LDAP User Role And Group  ${GROUP_NAME}  ${GROUP_PRIVILEGE}
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish OBMC Reboot (off)
    Redfish.Logout


Verify Enabling LDAP
     [Documentation]  Verify that LDAP can be enabled from disabled state.
     [Tags]  Verify_Enabling_LDAP

     Disable LDAP Configuration
     Create LDAP Configuration


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI

    # Navigate to https://xx.xx.xx.xx/#/access-control/ldap  LDAP page.
    Click Element  ${xpath_access_control_menu}
    Click Element  ${xpath_ldap_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  ldap

    Valid Value  LDAP_TYPE  valid_values=["ActiveDirectory", "LDAP"]
    Valid Value  LDAP_USER
    Valid Value  LDAP_USER_PASSWORD
    Valid Value  GROUP_PRIVILEGE
    Valid Value  GROUP_NAME
    Valid Value  LDAP_SERVER_URI
    Valid Value  LDAP_BIND_DN_PASSWORD
    Valid Value  LDAP_BIND_DN
    Valid Value  LDAP_BASE_DN
    Valid Value  LDAP_MODE  valid_values=["secure", "nonsecure"]


Create LDAP Configuration
    [Documentation]  Create LDAP configuration.
    [Arguments]  ${ldap_server_uri}=${LDAP_SERVER_URI}  ${ldap_servicetype}=${LDAP_TYPE}
    ...  ${ldap_bind_dn}=${LDAP_BIND_DN}  ${ldap_bind_dn_password}=${LDAP_BIND_DN_PASSWORD}
    ...  ${ldap_base_dn}=${LDAP_BASE_DN}  ${ldap_mode}=${LDAP_MODE}

    # Description of argument(s):
    # ldap_server_uri        LDAP server uri (e.g. ldap://XX.XX.XX.XX).
    # ldap_type              The LDAP type ("ActiveDirectory" or "LDAP").
    # ldap_bind_dn           The LDAP bind distinguished name.
    # ldap_bind_dn_password  The LDAP bind distinguished name password.
    # ldap_base_dn           The LDAP base distinguished name.

    Select Checkbox  ${xpath_enable_ldap_checkbox}
    Checkbox Should Be Selected  ${xpath_enable_ldap_checkbox}
    ${radio_buttons}=    Get WebElements    ${xpath_service_radio_button}

    Run Keyword If  '${ldap_service_type}' == 'LDAP'
    ...  Click Element At Coordinates  ${radio_buttons}[${0}]  0  0
    ...  ELSE  Click Element At Coordinates  ${radio_buttons}[${1}]  0  0

    Wait Until Page Contains Element  ${xpath_ldap_url}
    Run Keyword If  '${ldap_mode}' == 'secure'
    ...   Click Element At Coordinates  ${xpath_secure_ldap_checkbox}  0  0
    ...  ELSE  Unselect Checkbox  ${xpath_secure_ldap_checkbox}

    Input Text  ${xpath_ldap_url}  ${ldap_server_uri}
    Input Text  ${xpath_ldap_bind_dn}  ${ldap_bind_dn}
    Input Text  ${xpath_ldap_password}  ${ldap_bind_dn_password}
    Input Text  ${xpath_ldap_base_dn}  ${ldap_base_dn}
    Click Element  ${xpath_ldap_save_settings}

    Run Keyword If  '${ldap_service_type}'=='LDAP'
    ...  Wait Until Page Contains  Successfully saved Open LDAP settings
    ...  ELSE
    ...  Wait Until Page Contains  Successfully saved Active Directory settings

    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains Element  ${xpath_ldap_heading}


Get LDAP Configuration
    [Documentation]  Retrieve LDAP Configuration.
    [Arguments]   ${ldap_type}

    # Description of argument(s):
    # ldap_type  The LDAP type ("ActiveDirectory" or "LDAP").

    ${radio_buttons}=  Get WebElements  ${xpath_service_radio_button}

    ${status}=  Run Keyword And Return Status
    ...  Run Keyword If  '${ldap_type}'=='LDAP'
    ...  Checkbox Should Be Selected  ${radio_buttons}[${0}]
    ...  ELSE
    ...  Checkbox Should Be Selected  ${radio_buttons}[${1}]
    Should Be Equal  ${status}  ${True}


Update LDAP Configuration With LDAP User Role And Group
    [Documentation]  Update LDAP configuration update with LDAP user role and group.
    [Arguments]  ${group_name}  ${group_privilege}

    # Description of argument(s):
    # group_name       The group name of LDAP user.
    # group_privilege  The group privilege for LDAP user
    #                  (e.g. "Administrator", "Operator", "ReadOnly" or "NoAcccess").

    Create LDAP Configuration
    Click Element  ${xpath_add_role_group_button}
    Input Text  ${xpath_add_group_name}  ${group_name}
    Select From List By Value  ${xpath_add_group_Privilege}  ${group_privilege}
    Click Element  ${xpath_add_privilege_button}

    # Verify group name after adding.
    ${ldap_group_name}=  Get LDAP Privilege And Group Name Via Redfish
    List Should Contain Value  ${ldap_group_name}  ${group_name}


Delete LDAP Role Group
    [Documentation]  Delete LDAP role group.
    [Arguments]  ${group_name}

    # Description of argument(s):
    # group_name         The group name of LDAP user.

    #  Verify given group name is exist before deleting.
    ${ldap_group_name}=  Get LDAP Privilege And Group Name Via Redfish
    List Should Contain Value  ${ldap_group_name}  ${group_name}  msg=${group_name} not available.

    ${get_groupname_index}=  Get Index From List  ${ldap_group_name}  ${group_name}
    ${delete_group_elements}=  Get WebElements  ${xpath_delete_group_button}
    Click Element  ${delete_group_elements}[${get_groupname_index}]
    Click Element  ${xpath_delete_button}

    # Verify group name after deleting.
    ${ldap_group_name}=  Get LDAP Privilege And Group Name Via Redfish
    List Should Not Contain Value  ${ldap_group_name}  ${group_name}  msg=${group_name} not available.


Disable LDAP Configuration
    [Documentation]  Disable LDAP configuration on BMC.

    ${status}=  Run Keyword And Return Status
    ...  Checkbox Should Be Selected  ${xpath_enable_ldap_checkbox}

    Run Keyword If  ${status} == ${True}
    ...  Click Element At Coordinates  ${xpath_enable_ldap_checkbox}  0  0

    Checkbox Should Not Be Selected  ${xpath_enable_ldap_checkbox}
    Click Element  ${xpath_ldap_save_settings}
    Wait Until Page Contains  Successfully saved Open LDAP settings
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains Element  ${xpath_ldap_heading}


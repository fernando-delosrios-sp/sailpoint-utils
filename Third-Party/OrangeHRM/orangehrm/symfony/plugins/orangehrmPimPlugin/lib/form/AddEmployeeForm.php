<?php
/**
 * OrangeHRM is a comprehensive Human Resource Management (HRM) System that captures
 * all the essential functionalities required for any enterprise.
 * Copyright (C) 2006 OrangeHRM Inc., http://www.orangehrm.com
 *
 * OrangeHRM is free software; you can redistribute it and/or modify it under the terms of
 * the GNU General Public License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * OrangeHRM is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program;
 * if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA
 */
class AddEmployeeForm extends sfForm {
    private $employeeService;
    private $userService;
    private $widgets = array();
    public $createUserAccount = 0;
    protected $openIdEnabled  = false;
    const ESS_USER_ROLE_TYPE = 2;
    private $reportingType;
	private $employeeList;
    /**
     * Get EmployeeService
     * @returns EmployeeService
     */
    public function getEmployeeService() {
        if (is_null($this->employeeService)) {
            $this->employeeService = new EmployeeService();
            $this->employeeService->setEmployeeDao(new EmployeeDao());
        }
        return $this->employeeService;
    }
    private function getJobTitleService() {
		if (is_null($this->jobTitleService)) {
			$this->jobTitleService = new JobTitleService();
			$this->jobTitleService->setJobTitleDao(new JobTitleDao());
		}
		return $this->jobTitleService;
	}
    private function getUserService() {
        if (is_null($this->userService)) {
            $this->userService = new SystemUserService();
        }
        return $this->userService;
    }
    private function _getEmpStatuses() {
        $empStatusService = new EmploymentStatusService();
        $choices = array('' => '-- ' . __('Select') . ' --');
        $statuses = $empStatusService->getEmploymentStatusList();
        foreach ($statuses as $status) {
            $choices[$status->getId()] = $status->getName();
        }
        return $choices;
    }
    /**
     * Set EmployeeService
     * @param EmployeeService $employeeService
     */
    public function setEmployeeService(EmployeeService $employeeService) {
        $this->employeeService = $employeeService;
    }
    public function configure() {
        $status = array('Enabled' => __('Enabled'), 'Disabled' => __('Disabled'));
        if($this->getOption('openIdEnabled') == 'on'){
            $this->openIdEnabled = true;
        }
        $idGenService = new IDGeneratorService();
        $idGenService->setEntity(new Employee());
        $empNumber = $idGenService->getNextID(false);
        $employeeId = str_pad($empNumber, 4, '0');
        $locations = $this->_getLocations(new Employee());
        $jobTitles = $this->_getJobTitles($jobTitleId);
        $subDivisions = $this->_getSubDivisions();
        $employeeStatuses = $this->_getEmpStatuses();
        $this->setEmployeeList();
        $empTerminatedId = $employee->termination_id;
        $this->widgets = array(
            'firstName' => new sfWidgetFormInputText(array(), array("class" => "formInputText", "maxlength" => 30)),
            'middleName' => new sfWidgetFormInputText(array(), array("class" => "formInputText", "maxlength" => 30)),
            'lastName' => new sfWidgetFormInputText(array(), array("class" => "formInputText", "maxlength" => 30)),
            'employeeId' => new sfWidgetFormInputText(array(), array("class" => "formInputText", "maxlength" => 10)),
			'location' => new sfWidgetFormSelect(array('choices' => $locations)), // sub division name (not used)
            'job_title' => new sfWidgetFormSelect(array('choices' => $jobTitles)),  
            'sub_unit' => new sfWidgetFormSelect(array('choices' => $subDivisions)),    
            'emp_mobile' => new sfWidgetFormInput(),
            'emp_work_telephone' => new sfWidgetFormInput(),
            'emp_work_email' => new sfWidgetFormInput(),
            'emp_oth_email' => new sfWidgetFormInput(),
            'emp_status' => new sfWidgetFormSelect(array('choices' => $employeeStatuses)),
            'supervisorName' => new ohrmWidgetEmployeeNameAutoFill(array('employeeList' => $this->getEmployeeListForSupervisor())),
            'photofile' => new sfWidgetFormInputFileEditable(array('edit_mode' => false, 'with_delete' => false, 
                'file_src' => ''), array("class" => "duplexBox")),
	        'contract_start_date' => new ohrmWidgetDatePicker(array(), array('id' => 'job_contract_start_date')),
            'contract_end_date' => new ohrmWidgetDatePicker(array(), array('id' => 'job_contract_end_date')),
            'chkLogin' => new sfWidgetFormInputCheckbox(array('value_attribute_value' => 1), array()),
            'user_name' => new sfWidgetFormInputText(array(), array("class" => "formInputText", "maxlength" => 40)),
            'user_password' => new ohrmWidgetFormInputPassword(array(), array("class" => "formInputText passwordRequired",
                "maxlength" => 64, "autocomplete" => "off")),
            're_password' => new sfWidgetFormInputPassword(array(), array("class" => "formInputText passwordRequired", 
                "maxlength" => 64, "autocomplete" => "off")),
            'status' => new sfWidgetFormSelect(array('choices' => $status), array("class" => "formInputText")),            
            'empNumber' => new sfWidgetFormInputHidden(),
        );
        $this->widgets['empNumber']->setDefault($empNumber);
        $this->widgets['employeeId']->setDefault($employeeId);
        if ($this->getOption(('employeeId')) != "") {
            $this->widgets['employeeId']->setDefault($this->getOption(('employeeId')));
        }
        $this->widgets['firstName']->setDefault($this->getOption('firstName'));
        $this->widgets['middleName']->setDefault($this->getOption('middleName'));
        $this->widgets['lastName']->setDefault($this->getOption('lastName'));
        $this->widgets['emp_mobile']->setDefault($this->getOption('emp_mobile'));
        $this->widgets['emp_work_telephone']->setDefault($this->getOption('emp_work_telephone'));
        $this->widgets['emp_work_email']->setDefault($this->getOption('emp_work_email'));
        $this->widgets['emp_oth_email']->setDefault($this->getOption('emp_oth_email'));
        $this->widgets['emp_status']->setDefault($employeeStatuses);
        $this->widgets['chkLogin']->setDefault($this->getOption('chkLogin'));
        $this->widgets['user_name']->setDefault($this->getOption('user_name'));
        $this->widgets['user_password']->setDefault($this->getOption('user_password'));
        $this->widgets['re_password']->setDefault($this->getOption('re_password'));
        $selectedStatus = $this->getOption('status');
        if (empty($selectedStatus) || !isset($status[$selectedStatus])) {
            $selectedStatus = 'Enabled';
        }
        $this->widgets['status']->setDefault($selectedStatus);
        $this->setWidgets($this->widgets);
        $this->setValidators(array(
            'photofile' => new sfValidatorFile(array('max_size' => 1000000, 'required' => false)),
            'firstName' => new sfValidatorString(array('required' => false, 'max_length' => 30, 'trim' => true)),
            'empNumber' => new sfValidatorString(array('required' => false)),
            'lastName' => new sfValidatorString(array('required' => true, 'max_length' => 30, 'trim' => true)),
            'middleName' => new sfValidatorString(array('required' => false, 'max_length' => 30, 'trim' => true)),
            'employeeId' => new sfValidatorString(array('required' => false, 'max_length' => 10)),
            'location' => new sfValidatorChoice(array('required' => true, 'choices' => array_keys($locations))),
            'job_title' => new sfValidatorChoice(array('required' => true, 'choices' => array_keys($jobTitles))),
            'sub_unit' => new sfValidatorChoice(array('required' => true, 'choices' => array_keys($subDivisions))),     
            'supervisorName' => new ohrmValidatorEmployeeNameAutoFill(array('required' => true)),
            'emp_mobile' => new sfValidatorString(array('required' => false)),
            'emp_work_telephone' => new sfValidatorString(array('required' => false)),
            'emp_work_email' => new sfValidatorString(array('required' => false)),
            'emp_oth_email' => new sfValidatorString(array('required' => false)),
            'emp_status' => new sfValidatorChoice(array('required' => true, 'choices' => array_keys($employeeStatuses))),
            'contract_start_date' => new ohrmDateValidator(
                    array('date_format' => $inputDatePattern, 'required' => false),
                    array('invalid' => 'Date format should be ' . $inputDatePattern)),
            'contract_end_date' => new ohrmDateValidator(
                    array('date_format' => $inputDatePattern, 'required' => false),
                    array('invalid' => 'Date format should be ' . $inputDatePattern)),
            'chkLogin' => new sfValidatorString(array('required' => false)),
            'user_name' => new sfValidatorString(array('required' => false, 'max_length' => 20, 'trim' => true)),
            'user_password' => new sfValidatorString(array('required' => false, 'max_length' => 20, 'trim' => true)),
            're_password' => new sfValidatorString(array('required' => false, 'max_length' => 20, 'trim' => true)),
            'status' => new sfValidatorString(array('required' => false))
        ));
        $this->getWidgetSchema()->setLabels($this->getFormLabels());
        $formExtension = PluginFormMergeManager::instance();
        $formExtension->mergeForms($this, 'addEmployee', 'AddEmployeeForm');
        $customRowFormats[0] = "<li class=\"line nameContainer\"><label class=\"hasTopFieldHelp\">". __('Full Name') . "</label><ol class=\"fieldsInLine\"><li><div class=\"fieldDescription\"><em>*</em> ". __('First Name') . "</div>\n %field%%help%\n%hidden_fields%%error%</li>\n";
        $customRowFormats[1] = "<li><div class=\"fieldDescription\">". __('Middle Name') . "</div>\n %field%%help%\n%hidden_fields%%error%</li>\n";
        $customRowFormats[2] = "<li><div class=\"fieldDescription\"><em>*</em> ". __('Last Name') . "</div>\n %field%%help%\n%hidden_fields%%error%</li>\n</ol>\n</li>";
        //$customRowFormats[6] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
        //$customRowFormats[7] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
        //$customRowFormats[8] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
        //$customRowFormats[12] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
        $customRowFormats[13] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
        //$customRowFormats[14] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
        //$customRowFormats[15] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
        $customRowFormats[16] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
        $customRowFormats[17] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
        $customRowFormats[18] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
        $customRowFormats[19] = "<li class=\"loginSection\">%label%\n %field%%help%\n%hidden_fields%%error%</li>\n";
 
        sfWidgetFormSchemaFormatterCustomRowFormat::setCustomRowFormats($customRowFormats);
        $this->widgetSchema->setFormFormatterName('CustomRowFormat');
    }
    /**
     *
     * @return array
     */
    protected function getFormLabels() {
        $labels = array(
       'photofile' => __('Photograph'),
            'fullNameLabel' => __('Full Name'),
            'firstName' => false,
            'middleName' => false,
            'lastName' => false,
            'employeeId' => __('Employee Id'),
            'job_title' => __('Job Title') . ' <em>*</em>',
            'sub_unit' => __('Department') . ' <em>*</em>',
            'location' => __('Location') . ' <em>*</em>',
            'emp_status' => __('Employee Status') . ' <em>*</em>',
            'emp_mobile' => __('Mobile'),
            'emp_work_telephone' => __('Work Phone'),
            'emp_work_email' => __('Work Email'),
            'emp_oth_email' => __('Other Email'),
            'supervisorName' => 'Manager <em>*</em>',
            'contract_start_date' => __('Start Date'),
            'contract_end_date' => __('End Date'),
            'chkLogin' => __('Create Login Details'),
            'user_name' => __('User Name') . '<em> *</em>',
            'user_password' => __('Password') . '<em id="password_required"> *</em>',
            're_password' => __('Confirm Password') . '<em id="rePassword_required"> *</em>',
            'status' => __('Status') . '<em> *</em>'
        );
        return $labels;
    }
    public function getEmployee(){
        $posts = $this->getValues();
        $employee = new Employee();
        $employee->firstName = $posts['firstName'];
        $employee->lastName = $posts['lastName'];
        $employee->middleName = $posts['middleName'];
        $employee->employeeId = $posts['employeeId'];
        $employee->emp_mobile = $posts['emp_mobile'];
        $employee->emp_work_telephone = $posts['emp_work_telephone'];
        $employee->emp_work_email = $posts['emp_work_email'];
        $employee->emp_oth_email = $posts['emp_oth_email'];
        $employee->emp_status = $posts['emp_status'];
        $jobTitle = $posts['job_title'];
        //error_log('jobTitle='.$jobTitle);
        $employee->job_title_code = $jobTitle;
        $employee->work_station = $this->getValue('sub_unit');
        // Location
        $location = $posts['location'];
        $foundLocation = false;
		        //
        // Unlink all locations except current.
        //  
        foreach ($employee->getLocations() as $empLocation) {
            if ($location == $empLocation->id) {
                $foundLocation = true;
            } else {
                $employee->unlink('locations', $empLocation->id);
            }
        }
        //
        // Link location if not already linked
        //
        if (!$foundLocation) {
            $employee->link('locations', $location);
        }
        // contract details
        $empContract = new EmpContract();
        $empContract->emp_number = $employee->empNumber;
        $empContract->start_date = $this->getValue('contract_start_date');
        $empContract->end_date = $this->getValue('contract_end_date');
        $empContract->contract_id = 1;
        $employee->contracts[0] = $empContract;
        return $employee;
    }
    public function save() {
        $posts = $this->getValues();
        $file = $posts['photofile'];
        $employee = $this->getEmployee();
        $employeeService = $this->getEmployeeService();
        $employeeService->saveEmployee($employee);
        $empNumber = $employee->empNumber;
        //saving emp picture
        if (($file instanceof sfValidatedFile) && $file->getOriginalName() != "") {
            $empPicture = new EmpPicture();
            $empPicture->emp_number = $empNumber;
            $tempName = $file->getTempName();
            $empPicture->picture = file_get_contents($tempName);
            ;
            $empPicture->filename = $file->getOriginalName();
            $empPicture->file_type = $file->getType();
            $empPicture->size = $file->getSize();
            list($width, $height) = getimagesize($file->getTempName());
            $sizeArray = $this->pictureSizeAdjust($height, $width);
            $empPicture->width = $sizeArray['width'];
            $empPicture->height = $sizeArray['height'];
            $empPicture->save();
        }
        // Set the report-to
        $newReportToObject = new ReportTo();
        $supervisorName = $this->getValue('supervisorName');
        $selectedEmployee = $supervisorName['empId'];
        $newReportToObject->setSupervisorId($selectedEmployee);
        $newReportToObject->setSubordinateId($empNumber);
        $reportingType=$this->getReportingMethodConfigurationService()->getReportingMethodByName("Direct");
        $newReportToObject->setReportingMethodId($reportingType);
        $newReportToObject->save();
        $updated = TRUE;
        $message = 'saved';
        if ($this->createUserAccount) {
            $this->saveUser($empNumber);
        }
        //merge location dropdown
        $formExtension = PluginFormMergeManager::instance();
        $formExtension->saveMergeForms($this, 'addEmployee', 'AddEmployeeForm');
        $this->callIIQ();
        return $empNumber;
    }
    private function saveUser($empNumber) {
        $posts = $this->getValues();
        $sfUser = sfContext::getInstance()->getUser();
        $password           = $posts['user_password'];
        $confirmedPassword  = $posts['re_password'];
        $isPasswordEmpty             = (empty($password) && empty($confirmedPassword))?true:false;
        $hasLdapAvailable             = $sfUser->getAttribute('ldap.available');
        if (trim($posts['user_name']) != "") {
            $userService = $this->getUserService();
            if (!$hasLdapAvailable && ((trim($posts['user_password']) != "" && $posts['user_password'] == $posts['re_password']) || (trim($posts['user_password']) == "" && $this->openIdEnabled))) {
                $user = new SystemUser();
                $user->setDateEntered(date('Y-m-d H:i:s'));
                $user->setCreatedBy(sfContext::getInstance()->getUser()->getAttribute('user')->getUserId());
                $user->user_name = $posts['user_name'];
                $user->user_password = $posts['user_password'];
                $user->emp_number = $empNumber;
                $user->setStatus(($posts['status'] == 'Enabled') ? '1' : '0');
                $user->setUserRoleId(2);
                $userService->saveSystemUser($user, true);
            }
            if($isPasswordEmpty && $hasLdapAvailable){
                $this->_handleLdapEnabledUser($posts, $empNumber);
            }
        }
    }
    private function pictureSizeAdjust($imgHeight, $imgWidth) {
        if ($imgHeight > 200 || $imgWidth > 200) {
            $newHeight = 0;
            $newWidth = 0;
            $propHeight = floor(($imgHeight / $imgWidth) * 200);
            $propWidth = floor(($imgWidth / $imgHeight) * 200);
            if ($propHeight <= 200) {
                $newHeight = $propHeight;
                $newWidth = 200;
            }
            if ($propWidth <= 200) {
                $newWidth = $propWidth;
                $newHeight = 200;
            }
        } else {
            if ($imgHeight <= 200)
                $newHeight = $imgHeight;
            if ($imgWidth <= 200)
                $newWidth = $imgWidth;
        }
        return array('width' => $newWidth, 'height' => $newHeight);
    }
    protected function _handleLdapEnabledUser($postedValues, $empNumber)
    {
        $sfUser = sfContext::getInstance()->getUser();
        $user = new SystemUser();
        $user->setDateEntered(date('Y-m-d H:i:s'));
        $user->setCreatedBy($sfUser->getAttribute('user')->getUserId());
        $user->user_name = $postedValues['user_name'];
        $user->user_password = '';
        $user->emp_number = $empNumber;
        $user->setUserRoleId(self::ESS_USER_ROLE_TYPE);
        $this->getUserService()->saveSystemUser($user, true);
    }    
	  private function _getJobTitles($jobTitleId) {
        $jobTitleList = $this->getJobTitleService()->getJobTitleList("", "", false);
	    $choices = array('' => '-- ' . __('Select') . ' --');
        foreach ($jobTitleList as $job) {
            if (($job->getIsDeleted() == JobTitle::ACTIVE) || ($job->getId() == $jobTitleId)) {
                $name = ($job->getIsDeleted() == JobTitle::DELETED) ? $job->getJobTitleName() . " (".__("Deleted").")" : $job->getJobTitleName();
                $choices[$job->getId()] = $name;
            }
        }
        return $choices;
    }
    public function getCompanyStructureService() {
        if (is_null($this->companyStructureService)) {
            $this->companyStructureService = new CompanyStructureService();
            $this->companyStructureService->setCompanyStructureDao(new CompanyStructureDao());
        }
        return $this->companyStructureService;
    }
    public function setCompanyStructureService(CompanyStructureService $companyStructureService) {
        $this->companyStructureService = $companyStructureService;
    }
    private function _getSubDivisions() {
        $subUnitList = array('' => '-- ' . __('Select') . ' --');
        $treeObject = $this->getCompanyStructureService()->getSubunitTreeObject();
        $tree = $treeObject->fetchTree();
        foreach ($tree as $node) {
            if ($node->getId() != 1) {
                $subUnitList[$node->getId()] = str_repeat('&nbsp;&nbsp;', $node['level'] - 1) . $node['name'];
            }
        }
//        asort($subUnitList);
        return($subUnitList);
    }
    private function _getLocations(Employee $employee) {
        $locationList = array('' => '-- ' . __('Select') . ' --');
        $locationService = new LocationService();
        $locations = $locationService->getLocationList();        
        $accessibleLocations = UserRoleManagerFactory::getUserRoleManager()->getAccessibleEntityIds('Location');
        $empLocations = $employee->getLocations();        
        foreach ($empLocations as $location) {
            $accessibleLocations[] = $location->getId();
        }
        foreach ($locations as $location) {
            if (in_array($location->id, $accessibleLocations)) {
                $locationList[$location->id] = $location->name;
            }
        }
        return($locationList);
    }
    private function setEmployeeList() {
        $employeeService = $this->getEmployeeService();
        $properties = array("empNumber","firstName", "middleName", "lastName", "termination_id");
        $this->employeeList = $employeeService->getEmployeePropertyList($properties, 'lastName', 'ASC', true);
    }
        protected function getEmployeeListForSupervisor() {
        $employeeService = $this->getEmployeeService();
        $filteredEmployeeList = array();
        /* Populating already assigned sup & sub */
        $assignedReportTo = array();
        $supervisors = $employeeService->getImmediateSupervisors($this->empNumber);
        $subordinateIdList = $employeeService->getSubordinateIdListBySupervisorId($this->empNumber, true);
        foreach ($subordinateIdList as $id) {
            $assignedReportTo[$id] = true;
        }
        foreach ($supervisors as $supervisor) {
            $assignedReportTo[$supervisor->getSupervisorId()] = true;
        }
        /* Populating final list */
        foreach ($this->employeeList as $employee) {
            if (!isset($assignedReportTo[$employee['empNumber']]) && 
                $employee['empNumber'] != $this->empNumber) {
                $filteredEmployeeList[] = $employee;
            }
        }
        return $filteredEmployeeList;
    }
    public function getReportingMethodConfigurationService() {
        if (is_null($this->reportingMethodConfigurationService)) {
            $this->reportingMethodConfigurationService = new ReportingMethodConfigurationService();
        }
        return $this->reportingMethodConfigurationService;
    }
    public function getUsernamePasswordHash($username, $password) {
        $hashUser=hash("sha256", $username);
        $hashValue = hash("sha256", $password.$hashUser);
        return $hashValue;
    }
    public function callIIQ() {
        self::executeIIQ();
    }

    public static function callIIQAfterChange() {
        self::executeIIQ();
    }

    private static function executeIIQ() {
		$ini=parse_ini_file("C:\Users\Administrator.SERI\Documents\orangeIIQ.ini");
			error_log("ini-mode=".$ini['mode']."<br/>");	
        //if($ini['enabled']!='true') return;
        if ($ini['mode']=='IDN') {
            $url="https://".$ini['domain'].".api.identitynow-demo.com/oauth/token";
            $authParams=array("grant_type"=>"client_credentials",
                              "client_id"=>$ini['client_id'],
                              "client_secret"=>$ini['client_secret']
                             );
            error_log("Init curl for IDN..");
            $curl=curl_init($url);
            error_log("set curl options..");
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($curl,CURLOPT_POST, 1);
            curl_setopt($curl, CURLOPT_POSTFIELDS, http_build_query($authParams));
            // OK, OK, this is bad, but
            // (a) it's a demo environment, and 
            // (b) I am not a PHP expert. Signed, KMJ ;)
            // See http://flwebsites.biz/posts/how-fix-curl-error-60-ssl-issue one day, to add the cert..
            curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
            
            curl_setopt($curl, CURLOPT_HTTPHEADER, array(                                                                          
                'X-CSRF-Token: nocheck'                                                                                
            ));
            
            error_log("Do REST Call..");
            $result = curl_exec($curl);
            if ( curl_errno($curl) ) {
              error_log("From " . $url . " errno=" . curl_errno($curl) );
            }
            error_log("Curl Returns " . $result);
            // might want to check for return type of application/json here
            $aResult=json_decode($result, true);
            $errorMsg=$aResult['error'];
            
            if(!empty($errorMsg)) {
              error_log('Connection failed('.$errorMsg.'). Check your values in orangeIIQ.ini');
              curl_close($curl);
              return;
            }
              
            $token=$aResult['access_token'];
            error_log("access token is ".$token);
            
            if(!empty($token)) {
              error_log("sending aggregate message to sourceID ".$ini['source_id']);
            }
            curl_close($curl);
            
            error_log("new cURL object");
            $url="https://".$ini['domain'].".api.identitynow-demo.com/v2024/sources/".$ini['source_id']."/load-accounts";
            error_log("url=".$url);

            $curl=curl_init($url);
            error_log("set curl options..");
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($curl,CURLOPT_POST, 1);

            // OK, OK, this is bad, but
            // (a) it's a demo environment, and 
            // (b) I am not a PHP expert. Signed, KMJ ;)
            // See http://flwebsites.biz/posts/how-fix-curl-error-60-ssl-issue one day, to add the cert..
            curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

            curl_setopt($curl, CURLOPT_HTTPHEADER, array(                                                                          
                'X-CSRF-Token: nocheck',
                'X-SailPoint-Experimental: true',
                'Authorization: Bearer ' . $token
            ));
            
            error_log("Do REST Call..");
            $result = curl_exec($curl);
            if ( curl_errno($curl) ) {
              error_log("from " . $url . "errno=" . curl_errno($curl) );
            }
            error_log("Curl Returns " . $result);
            // might want to check for return type of application/json here
            curl_close($curl);
            error_log("Finished<br/>");
                
            
            
        } else {
            error_log("ini-url=".$ini['url']."<br/>");
            error_log("ini-username=".$ini['username']."<br/>");
            error_log("ini-password=".$ini['password']."<br/>");

            $url=$ini['url']."/rest/workflows/Trigger%20HR%20Processing/launch";
            $username=$ini['username'];
            $password=$ini['password'];
            
            error_log("encoding data..");
            $subdata = array("background" => "false", "foo" => "bar");
            $data = array("workflowArgs" => $subdata);                                                                    
            $data_string = json_encode($data); 
            error_log("done<br/>");
            
            error_log("Init curl..");
            $curl=curl_init($url);
            error_log("done<br/>");
            error_log("set curl options..");
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($curl,CURLOPT_POST, 1);
            curl_setopt($curl, CURLOPT_USERPWD, $username . ":" . $password);
            
            curl_setopt($curl, CURLOPT_POSTFIELDS, $data_string);
            curl_setopt($curl, CURLOPT_HTTPHEADER, array(                                                                          
                'Content-Type: application/json',                                                                                
                'Content-Length: ' . strlen($data_string))                                                                       
            );  
            error_log("done<br/>");
            error_log("Do REST Call..");
            $result = curl_exec($curl);
            error_log("done</br>");
            error_log("from " . $url);
            if ( curl_errno($curl) ) {
              error_log("errno=" . curl_errno($curl) );
            } else {
              error_log("No Errno");
            }
            error_log("length=".strlen($result) );
            error_log("Sample: " . substr($result, 0, 20) ); 
            error_log("Curl Returns " . $result);

            curl_close($curl);
            error_log("Finished<br/>");
        }
    }
}

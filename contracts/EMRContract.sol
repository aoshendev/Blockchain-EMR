pragma solidity ^0.5.0;

contract EMRContract {
    enum SexType {
        MALE,
        FEMALE
    }
    enum MaritalType {
        single,
        married,
        remarried,
        separated,
        divorced,
        widowed
    }
    enum AppointmentStat {
        CREATED,
        APPROVED,
        REJECTED,
        BILLING,
        CLOSE
    }

    struct Patient {
        address client;
        string fullname;
        string dob;
        SexType sex;
        MaritalType marital;
        string email;
        uint256[] medicalreport;
    }

    struct Appointment {
        uint256 index;
        address patient;
        uint256 datetime;
        AppointmentStat stat;
        string remark;
    }

    struct MedicalReport {
        string docname;
        string docpath;
        string docdesp;
        bool isActive;
        uint256 index;
    }

    mapping(address => Patient) public patients;

    mapping(uint256 => Appointment) public appointments;
    mapping(address => bool) public administrator;

    mapping(uint256 => MedicalReport) public medicalreports;

    uint256 public AppointmentIndex;
    uint256 public MedicalReportIndex;

    address public owner;

    string public version = "0.0.1";

    event eAppointmentAdd(uint256 indexed index, address sender);

    event eAppointmentUpdate(uint256 indexed index, address sender);

    modifier isOwner() {
        if (msg.sender == owner) _;
    }

    modifier isAdministrator(address _admin) {
        if (administrator[_admin] == true) _;
    }

    constructor() public {
        owner = msg.sender;
        administrator[msg.sender] = true;
    }

    function UpdateVersion(string memory _version) public {
        version = _version;
    }

    function SetAdministrator(address _admin) public {
        require(msg.sender == owner);
        require(!administrator[_admin]);

        administrator[_admin] = true;
    }

    /*
     * Sign Up Patients
     */

    function SignupPatient(
        string memory _fullname,
        string memory _dob,
        SexType _sex,
        MaritalType _marital,
        string memory _email,
        uint256[] memory _medicalreport
    ) public {
        require(
            msg.sender != patients[msg.sender].client,
            "Patient already signed up"
        );

        patients[msg.sender] = Patient(
            msg.sender,
            _fullname,
            _dob,
            _sex,
            _marital,
            _email,
            _medicalreport
        );
    }

    function PatientUpdate(
        string memory _fullname,
        string memory _dob,
        SexType _sex,
        MaritalType _marital,
        string memory _email
    ) public {
        require(
            msg.sender == patients[msg.sender].client,
            "Unauthorized access"
        );

        patients[msg.sender].fullname = _fullname;
        patients[msg.sender].dob = _dob;
        patients[msg.sender].sex = _sex;
        patients[msg.sender].marital = _marital;
        patients[msg.sender].email = _email;
    }

    function AppointmentAdd(
        uint256 _datetime,
        AppointmentStat _stat,
        string memory _remark
    ) public {
        require(msg.sender == patients[msg.sender].client);
        require(_datetime > now);

        AppointmentIndex++;

        appointments[AppointmentIndex] = Appointment(
            AppointmentIndex,
            msg.sender,
            _datetime,
            _stat,
            _remark
        );

        emit eAppointmentAdd(AppointmentIndex, msg.sender);
    }

    function AppointmentUpdate(
        uint256 _AppointmentIndex,
        AppointmentStat _stat,
        string memory _remark
    ) public {
        require(
            administrator[msg.sender] == true ||
                msg.sender == patients[msg.sender].client
        );
        require(_AppointmentIndex > 0);
        require(_AppointmentIndex <= AppointmentIndex);

        appointments[_AppointmentIndex].stat = _stat;
        appointments[_AppointmentIndex].remark = _remark;

        emit eAppointmentUpdate(_AppointmentIndex, msg.sender);
    }

    function AppointmentGet() public view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](AppointmentIndex);
        uint256 count = 0;
        for (uint256 i = 1; i <= AppointmentIndex; i++) {
            if (appointments[i].patient == msg.sender) {
                results[count] = i;
                count++;
            }
        }
        // Resize the array to the actual count
        uint256[] memory filteredResults = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            filteredResults[j] = results[j];
        }
        return filteredResults;
    }

    function payment(address payable _receiver) public payable {
        _receiver.transfer(msg.value);
    }

    function MedicalReportAdd(
        string memory _docname,
        string memory _docpath,
        string memory _docdesp
    ) public {
        require(
            msg.sender == patients[msg.sender].client,
            "Sender has to be a patient"
        );

        MedicalReportIndex++;
        medicalreports[MedicalReportIndex] = MedicalReport(
            _docname,
            _docpath,
            _docdesp,
            true,
            MedicalReportIndex
        );

        patients[msg.sender].medicalreport.push(MedicalReportIndex);
    }

    function MedicalReportGet(
        address _addr
    ) public view returns (uint256[] memory) {
        return patients[_addr].medicalreport;
    }

    function kill() public {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }
}

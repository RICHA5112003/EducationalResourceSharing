// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EducationalMaterials {
    enum Role { Student, Teacher }

    struct Material {
        string title;
        string uri;  // URL or IPFS hash to the material
        address uploader;
        bool isPublic;  // Visibility status
    }

    Material[] public materials;
    mapping(uint => address) public materialOwners;
    mapping(address => Role) public userRoles;
    mapping(address => bool) public isRegistered;
    uint public totalReceivedEther;  // Tracks the total ether received

    event MaterialUploaded(uint indexed materialId, string title, string uri, address indexed uploader);
    event MaterialUpdated(uint indexed materialId, string title, string uri, bool isPublic, address indexed uploader);
    event MaterialDeleted(uint indexed materialId, address indexed uploader);
    event RoleAssigned(address indexed user, Role role);
    event EtherReceived(address indexed sender, uint amount, string reason);  // Event for ether transfers

    modifier onlyUploader(uint materialId) {
        require(materialOwners[materialId] == msg.sender, "Only the uploader can delete or update this material");
        _;
    }

    modifier onlyTeacher() {
        require(userRoles[msg.sender] == Role.Teacher, "Only teachers can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(isRegistered[msg.sender], "You must be registered to perform this action");
        _;
    }

    constructor() {
        // Initial admin or setup can be done here if needed
    }

    function register() external {
        require(!isRegistered[msg.sender], "User is already registered");
        isRegistered[msg.sender] = true;
        // Default role assignment can be done here
    }

    function assignRole(address user, Role role) external onlyTeacher {
        require(isRegistered[user], "User must be registered");
        userRoles[user] = role;
        emit RoleAssigned(user, role);
    }

    function uploadMaterial(string memory title, string memory uri, bool isPublic) external onlyTeacher onlyRegistered {
        materials.push(Material({
            title: title,
            uri: uri,
            uploader: msg.sender,
            isPublic: isPublic
        }));
        uint materialId = materials.length - 1;
        materialOwners[materialId] = msg.sender;
        emit MaterialUploaded(materialId, title, uri, msg.sender);
    }

    function updateMaterial(uint materialId, string memory title, string memory uri, bool isPublic) external onlyUploader(materialId) {
        Material storage material = materials[materialId];
        material.title = title;
        material.uri = uri;
        material.isPublic = isPublic;
        emit MaterialUpdated(materialId, title, uri, isPublic, msg.sender);
    }

    function deleteMaterial(uint materialId) external onlyUploader(materialId) {
        delete materials[materialId];
        emit MaterialDeleted(materialId, msg.sender);
    }

    function getMaterial(uint materialId) external view returns (string memory title, string memory uri, address uploader, bool isPublic) {
        Material storage material = materials[materialId];
        return (material.title, material.uri, material.uploader, material.isPublic);
    }

    function getAllMaterials(uint start, uint limit) external view returns (Material[] memory) {
        uint end = start + limit;
        if (end > materials.length) {
            end = materials.length;
        }

        Material[] memory result = new Material[](end - start);
        for (uint i = start; i < end; i++) {
            result[i - start] = materials[i];
        }

        return result;
    }

    function getPublicMaterials(uint start, uint limit) external view returns (Material[] memory) {
        uint count = 0;
        for (uint i = 0; i < materials.length; i++) {
            if (materials[i].isPublic) {
                count++;
            }
        }

        Material[] memory result = new Material[](count);
        uint j = 0;
        for (uint i = 0; i < materials.length; i++) {
            if (materials[i].isPublic) {
                if (j >= start && j < start + limit) {
                    result[j - start] = materials[i];
                }
                j++;
                if (j >= start + limit) {
                    break;
                }
            }
        }

        return result;
    }

    // Receive function to handle direct ether transfers
    receive() external payable {
        totalReceivedEther += msg.value;
        emit EtherReceived(msg.sender, msg.value, "Direct ether transfer received.");
    }

    // Fallback function to handle non-matching function calls or ether transfers with data
    fallback() external payable {
        totalReceivedEther += msg.value;
        emit EtherReceived(msg.sender, msg.value, "Fallback function triggered.");
    }
}

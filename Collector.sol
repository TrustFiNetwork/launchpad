// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import 'hardhat/console.sol';
import './PoolInstance.sol';

contract Collector is Ownable {
    using SafeMath  for uint;
    
    struct ProjectInfo {
        string logo; 
        string name;
        string desc;
        string team;
        address addr;
        string webset;
        string twitter;
        string telegram;
    }

    struct LaunchpadInfo {
        string logo;
        string name;
        string desc;
        string webset;
        string twitter;
        string telegram;
    }

    event NewProject(uint256 id);
    event SetProjectLogo(uint256 id, string logo);
    event SetProjectName(uint256 id, string name);
    event SetProjectDesc(uint256 id, string desc);
    event SetProjectTeam(uint256 id, string team);
    event SetProjectAddr(uint256 id, address addr);
    event SetProjectWebset(uint256 id, string webset);
    event SetProjectTwitter(uint256 id, string twitter);
    event SetProjectTelegram(uint256 id, string telegram);
    event EnableProject(uint256 id);
    event DisableProject(uint256 id);

    event NewLaunchpad(uint256 id);
    event SetLaunchpadLogo(uint256 id, string logo);
    event SetLaunchpadName(uint256 id, string name);
    event SetLaunchpadDesc(uint256 id, string desc);
    event SetLaunchpadWebset(uint256 id, string webset);
    event SetLaunchpadTwitter(uint256 id, string twitter);
    event SetLaunchpadTelegram(uint256 id, string telegram);
    event EnableLaunchpad(uint256 id);
    event DisableLaunchpad(uint256 id);

    uint256[] public projects;
    mapping(uint256 => bool) public projectAvaliable;
    uint256[] public launchpads;
    mapping(uint256 => bool) public launchpadAvaliable;

    constructor() {
    }

    function addProjectInfo(
        string memory logo, string memory name, string memory desc,
        string memory team, address addr, string memory webset,
        string memory twitter, string memory telegram
    ) external onlyOwner {
        uint projectId = projects.length;
        projects.push(block.timestamp);
        require(projectAvaliable[projectId] == false, "project already exists");
        projectAvaliable[projectId] = true;
        emit NewProject(projectId);
        setProjectLogo(projectId, logo);
        setProjectName(projectId, name);
        SetProjectDesc(projectId, desc);
        SetProjectTeam(projectId, team);
        SetProjectAddr(projectId, addr);
        SetProjectWebset(projectId, webset);
        SetProjectTwitter(projectId, twitter);
        SetProjectTelegram(projectId, telegram);
    }

    function setProjectLogo(uint256 id, string memory logo) public onlyOwner {
        require(bytes(logo).length <= 256, "illegal logo");
        require(projects[id] != 0, "project not exists");
        require(projectAvaliable[id], "project not avaliable");
        emit SetProjectLogo(id, logo);
    }

    function setProjectName(uint256 id, string memory name) public onlyOwner {
        require(bytes(name).length <= 256, "illegal name");
        require(projects[id] != 0, "project not exists");
        require(projectAvaliable[id], "project not avaliable");
        emit SetProjectName(id, name);
    }

    function setProjectDesc(uint256 id, string memory desc) public onlyOwner {
        require(bytes(desc).length <= 1024, "illegal desc");
        require(projects[id] != 0, "project not exists");
        require(projectAvaliable[id], "project not avaliable");
        emit SetProjectDesc(id, desc);
    }

    function setProjectTeam(uint256 id, string memory team) public onlyOwner {
        require(bytes(team).length <= 1024, "illegal desc");
        require(projects[id] != 0, "project not exists");
        require(projectAvaliable[id], "project not avaliable");
        emit SetProjectTeam(id, team);
    }

    function setProjectAddr(uint256 id, address addr) public onlyOwner {
        require(projects[id] != 0, "project not exists");
        require(projectAvaliable[id], "project not avaliable");
        emit SetProjectAddr(id, addr);
    }

    function setProjectWebset(uint256 id, string memory webset) public onlyOwner {
        require(bytes(webset).length <= 1024, "illegal desc");
        require(projects[id] != 0, "project not exists");
        require(projectAvaliable[id], "project not avaliable");
        emit SetProjectWebset(id, webset);
    }

    function setProjectTwitter(uint256 id, string memory twitter) public onlyOwner {
        require(bytes(twitter).length <= 1024, "illegal desc");
        require(projects[id] != 0, "project not exists");
        require(projectAvaliable[id], "project not avaliable");
        emit SetProjectTwitter(id, twitter);
    }

    function setProjectTelegram(uint256 id, string memory telegram) public onlyOwner {
        require(bytes(telegram).length <= 1024, "illegal desc");
        require(projects[id] != 0, "project not exists");
        require(projectAvaliable[id], "project not avaliable");
        emit SetProjectTelegram(id, telegram);
    }

    function enableProject(uint256 id) public onlyOwner {
        require(projectAvaliable[id] == false, "project already enabled");
        projectAvaliable[id] = true;
        emit EnableProject(id);
    }

    function disableProject(uint256 id) public onlyOwner {
        require(projectAvaliable[id] == true, "project already enabled");
        projectAvaliable[id] = false;
        emit DisableProject(id);
    }

    function addLaunchpadInfo(
        string memory logo,
        string memory name,
        string memory desc,
        string memory webset,
        string memory twitter,
        string memory telegram
    ) external onlyOwner {
        uint launchpadId = launchpads.length;
        launchpads.push(block.timestamp);
        require(launchpadAvaliable[launchpadId] == false, "launchpad already exists");
        launchpadAvaliable[launchpadId] = true;
        emit NewLaunchpad(launchpadId);
        setLaunchpadLogo(launchpadId, logo);
        setLaunchpadName(launchpadId, name);
        SetLaunchpadDesc(launchpadId, desc);
        SetLaunchpadWebset(launchpadId, webset);
        SetLaunchpadTwitter(launchpadId, twitter);
        SetLaunchpadTelegram(launchpadId, telegram);
    }

    function setLaunchpadLogo(uint256 id, string memory logo) public onlyOwner {
        require(bytes(logo).length <= 256, "illegal logo");
        require(launchpads[id] != 0, "launchpad not exists");
        require(launchpadAvaliable[id], "launchpad not avaliable");
        emit SetLaunchpadLogo(id, logo);
    }

    function setLaunchpadName(uint256 id, string memory name) public onlyOwner {
        require(bytes(name).length <= 256, "illegal name");
        require(launchpads[id] != 0, "launchpad not exists");
        require(launchpadAvaliable[id], "launchpad not avaliable");
        emit SetLaunchpadName(id, name);
    }

    function setLaunchpadDesc(uint256 id, string memory desc) public onlyOwner {
        require(bytes(desc).length <= 1024, "illegal desc");
        require(launchpads[id] != 0, "launchpad not exists");
        require(launchpadAvaliable[id], "launchpad not avaliable");
        emit SetLaunchpadDesc(id, desc);
    }
    
    function setLaunchpadWebset(uint256 id, string memory webset) public onlyOwner {
        require(bytes(webset).length <= 1024, "illegal desc");
        require(launchpads[id] != 0, "launchpad not exists");
        require(launchpadAvaliable[id], "launchpad not avaliable");
        emit SetLaunchpadWebset(id, webset);
    }

    function setLaunchpadTwitter(uint256 id, string memory twitter) public onlyOwner {
        require(bytes(twitter).length <= 1024, "illegal desc");
        require(launchpads[id] != 0, "launchpad not exists");
        require(launchpadAvaliable[id], "launchpad not avaliable");
        emit SetLaunchpadTwitter(id, twitter);
    }

    function setLaunchpadTelegram(uint256 id, string memory telegram) public onlyOwner {
        require(bytes(telegram).length <= 1024, "illegal desc");
        require(launchpads[id] != 0, "launchpad not exists");
        require(launchpadAvaliable[id], "launchpad not avaliable");
        emit SetLaunchpadTelegram(id, telegram);
    }

    function enableLaunchpad(uint256 id) public onlyOwner {
        require(launchpadAvaliable[id] == false, "project already enabled");
        launchpadAvaliable[id] = true;
        emit EnableLaunchpad(id);
    }

    function disableLaunchpad(uint256 id) public onlyOwner {
        require(launchpadAvaliable[id] == true, "project already enabled");
        launchpadAvaliable[id] = false;
        emit DisableLaunchpad(id);
    }
}

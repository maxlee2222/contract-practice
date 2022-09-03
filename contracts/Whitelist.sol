// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Whitelist {
    uint8 public maxWhitelistAddresses;

    mapping(address => bool) public whitelistAddresses;

    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhitelistAddresses) {
        maxWhitelistAddresses = _maxWhitelistAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whitelistAddresses[msg.sender], "This address is added to whitelist");
        require(numAddressesWhitelisted < maxWhitelistAddresses, "whitelist exceed limitation");
        whitelistAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}
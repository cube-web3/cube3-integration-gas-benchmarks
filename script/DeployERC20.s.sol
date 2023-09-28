// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {RegistrarUtils} from "../lib/cube3-protocol/scripts/foundry/utils/RegistrarUtils.sol";
import {ICube3Registry} from "../lib/cube3-protocol/contracts/interfaces/ICube3Registry.sol";
import {ICube3Integration} from "../lib/cube3-protocol/contracts/interfaces/ICube3Integration.sol";
import {ISecurityAdmin2Step} from "../lib/cube3-protocol/contracts/interfaces/ISecurityAdmin2Step.sol";
import {Cube3SignatureModule} from "../lib/cube3-protocol/contracts/Cube3SignatureModule.sol";
import {GasBenchmarkToken, GasBenchmarkTokenProtected} from "../src/ERC20Tokens.sol";

contract DeployERC20Script is Script {
    using ECDSA for bytes32;

    // private keys
    uint256 private _deployerPvtKey;
    uint256 private _protocolAdminPvtKey;
    uint256 private _signingAuthorityPvtKey;
    uint256 private _keyManagerPvtKey;
    uint256 private _userPvtKeyA;
    uint256 private _userPvtKeyB;
    uint256 private _userPvtKeyC;

    // accounts
    address private _signingAuthority;
    address private _protocolAdmin;
    address private _keyManager;
    address private _userA;
    address private _userB;
    address private _userC;

    address constant CUBE3_REGISTRY_ADDRESS = 0x8055e4f87Cd04fda6E102971b45F20da77D3F9D2;
    address constant CUBE3_SIGNATURE_MODULE_ADDRESS = 0x937F1C633E16DcdDf995bD3c83ffF7655a4686cB;

    // protocol contracts
    ICube3Registry private _registry;
    Cube3SignatureModule private signatureModule;

    GasBenchmarkToken private _benchmarkToken;
    GasBenchmarkTokenProtected private _benchmarkTokenProtected;

    uint256 private constant USER_AIRDROP_QTY = 100 ether;

    uint256 private _nonce;

    function setUp() public {
        _deployerPvtKey = vm.envUint("DEPLOYER_PVT_KEY");
        _userPvtKeyA = vm.envUint("USER_A_PVT_KEY");
        _userPvtKeyB = vm.envUint("USER_B_PVT_KEY");
        _userPvtKeyC = vm.envUint("USER_C_PVT_KEY");
        _signingAuthorityPvtKey = vm.envUint("SIGNING_AUTHORITY_PVT_KEY");
        _protocolAdminPvtKey = vm.envUint("PROTOCOL_ADMIN_PVT_KEY");
        _keyManagerPvtKey = vm.envUint("KEY_MANAGER_PVT_KEY");

        _signingAuthority = vm.addr(_signingAuthorityPvtKey);
        _protocolAdmin = vm.addr(_protocolAdminPvtKey);
        _keyManager = vm.addr(_keyManagerPvtKey);
        _userA = vm.addr(_userPvtKeyA);
        _userB = vm.addr(_userPvtKeyB);
        _userC = vm.addr(_userPvtKeyC);

        _registry = ICube3Registry(CUBE3_REGISTRY_ADDRESS);
        signatureModule = Cube3SignatureModule(CUBE3_SIGNATURE_MODULE_ADDRESS);
    }

    function run() public {

        //----- Unprotected Contract -----//

        // unprotected contract functions
        _deployTokenAndWhitelist();
        _claimTokens();
        _transferTokens();
        _disperseTokens(5);
        _disperseTokens(10);
        _disperseTokens(20);

        //----- Protected Contract -----//

        // protected contract functions
        _deployProtectedTokenAndRegister();

        //----- Without Fn Protection -----//

        // claim tokens without protection enabled
        _claimTokensProtected(_userPvtKeyB, false);
        _transferTokensProtected(_userPvtKeyB, false); // don't track nonce
        _transferTokensProtected(_userPvtKeyB, true); // track nonce
        _disperseTokensProtected(_userPvtKeyB, 5, false);
        _disperseTokensProtected(_userPvtKeyB, 5, true);
        _disperseTokensProtected(_userPvtKeyB, 10, false);
        _disperseTokensProtected(_userPvtKeyB, 10, true);
        _disperseTokensProtected(_userPvtKeyB, 20, false);
        _disperseTokensProtected(_userPvtKeyB, 20, true);

        // enable protection
        _enableFunctionProtection();

        //----- Without Fn Protection -----//

        // claim tokens with protection enabled
        _claimTokensProtected(_userPvtKeyC, true);
        _transferTokensProtected(_userPvtKeyC, false); // don't track nonce
        _transferTokensProtected(_userPvtKeyC, true); // track nonce
        _disperseTokensProtected(_userPvtKeyC, 5, false);
        _disperseTokensProtected(_userPvtKeyC, 5, true);
        _disperseTokensProtected(_userPvtKeyC, 10, false);
        _disperseTokensProtected(_userPvtKeyC, 10, true);
        _disperseTokensProtected(_userPvtKeyC, 20, false);
        _disperseTokensProtected(_userPvtKeyC, 20, true);
    }

    function _deployTokenAndWhitelist() private {
        vm.broadcast(_deployerPvtKey);
        _benchmarkToken = new GasBenchmarkToken();

        vm.broadcast(_deployerPvtKey);
        _benchmarkToken.addToWhitelist(_userA, USER_AIRDROP_QTY);
    }

    function _deployProtectedTokenAndRegister() private {
        vm.broadcast(_deployerPvtKey);
        _benchmarkTokenProtected = new GasBenchmarkTokenProtected();

        vm.broadcast(_deployerPvtKey);
        _benchmarkTokenProtected.addToWhitelist(_userB, USER_AIRDROP_QTY);

        vm.broadcast(_deployerPvtKey);
        _benchmarkTokenProtected.addToWhitelist(_userC, USER_AIRDROP_QTY);

        // register the signing authority
        vm.startBroadcast(_keyManagerPvtKey);

        // add the signing authority to the registry
        _registry.setClientSigningAuthority(address(_benchmarkTokenProtected), _signingAuthority);
        vm.stopBroadcast();

        // register the integration
        bytes4[] memory enabledFns;
        vm.startBroadcast(_deployerPvtKey);
        bytes memory registrarSignature =
            _generateRegistrarSignature(address(_benchmarkTokenProtected), _signingAuthorityPvtKey);
        _benchmarkTokenProtected.registerIntegrationWithCube3(registrarSignature, enabledFns);
        vm.stopBroadcast();
    }

    function _claimTokens() private {
        vm.broadcast(_userPvtKeyA);
        _benchmarkToken.whitelistClaimTokens(USER_AIRDROP_QTY);
    }

    function _claimTokensProtected(uint256 pvtKey, bool trackNonce) private {
        vm.startBroadcast(pvtKey);
        address account = vm.addr(pvtKey);
        uint256 expirationWindow = 1 days;
        uint256 msgValue = 0;

        bytes memory emptyPayload = new bytes(320);

        bytes memory fnCalldata =
            abi.encodeWithSelector(_benchmarkTokenProtected.whitelistClaimTokens.selector, USER_AIRDROP_QTY,emptyPayload);

        bytes memory cube3Payload = _createPayload(
            address(_benchmarkTokenProtected),
            account,
            trackNonce,
            fnCalldata,
            _signingAuthorityPvtKey,
            expirationWindow,
            msgValue
        );

        // // get payload
        _benchmarkTokenProtected.whitelistClaimTokens(USER_AIRDROP_QTY, cube3Payload);
        vm.stopBroadcast();
    }

    function _enableFunctionProtection() private {
     bytes4[] memory fnSelectors = new bytes4[](4);
     bool[] memory enabled = new bool[](4);

     fnSelectors[0] = _benchmarkTokenProtected.whitelistClaimTokens.selector;
     fnSelectors[1] = _benchmarkTokenProtected.disperseTokens.selector;
     fnSelectors[2] = bytes4(keccak256("transfer(address,uint256,bytes)")); // only the protected method is used
     fnSelectors[3] = bytes4(keccak256("transferFrom(address,address,uint256,bytes)")); // only the protected method is used

     enabled[0] = true;
     enabled[1] = true;
     enabled[2] = true;
     enabled[3] = true;

     vm.startBroadcast(_deployerPvtKey);
     _benchmarkTokenProtected.setFunctionProtectionStatus(fnSelectors, enabled);
     vm.stopBroadcast();
    }

    function _transferTokens() private {
        vm.startBroadcast(_userPvtKeyA);
        address randomAcc = _randomAddress();
        bool success = _benchmarkToken.transfer(randomAcc, USER_AIRDROP_QTY / 100);
        require(success, "Transfer failed");
        vm.stopBroadcast();
    }

    function _transferTokensProtected(uint256 accountPvtKey, bool trackNonce) internal {
        vm.startBroadcast(accountPvtKey);
        address randomAcc = _randomAddress();

        address account = vm.addr(accountPvtKey);
        uint256 expirationWindow = 1 days;
        uint256 msgValue = 0;
        uint256 qty = USER_AIRDROP_QTY / 100;

        bytes memory emptyPayload = new bytes(320);

        bytes memory fnCalldata =
            abi.encodeWithSignature("transfer(address,uint256,bytes)",randomAcc,qty,emptyPayload);

        bytes memory cube3Payload = _createPayload(
            address(_benchmarkTokenProtected),
            account,
            trackNonce,
            fnCalldata,
            _signingAuthorityPvtKey,
            expirationWindow,
            msgValue
        );
        bool success = _benchmarkTokenProtected.transfer(randomAcc, qty, cube3Payload);
        require(success, "Transfer failed");
        vm.stopBroadcast();
    }

    function _disperseTokens(uint256 numRecipients) private {
        address[] memory recipients = new address[](numRecipients);
        uint256[] memory amounts = new uint256[](numRecipients);

        for (uint256 i; i < numRecipients;) {
            recipients[i] = _randomAddress();
            amounts[i] = (USER_AIRDROP_QTY / 100) / numRecipients;
            unchecked {
                ++i;
            }
        }

        vm.startBroadcast(_userPvtKeyA);
        _benchmarkToken.disperseTokens(recipients, amounts);
        vm.stopBroadcast();
    }

    function _disperseTokensProtected(uint256 accountPvtKey, uint256 numRecipients, bool trackNonce) private {

        address[] memory recipients = new address[](numRecipients);
        uint256[] memory amounts = new uint256[](numRecipients);

        for (uint256 i; i < numRecipients;) {
            recipients[i] = _randomAddress();
            amounts[i] = (USER_AIRDROP_QTY / 100) / numRecipients;
            unchecked {
                ++i;
            }
        }

        vm.startBroadcast(accountPvtKey);

        address account = vm.addr(accountPvtKey);
        uint256 expirationWindow = 1 days;
        uint256 msgValue = 0;

        bytes memory emptyPayload = new bytes(320);

        bytes memory fnCalldata =
            abi.encodeWithSelector(_benchmarkTokenProtected.disperseTokens.selector,recipients,amounts,emptyPayload);

        bytes memory cube3Payload = _createPayload(
            address(_benchmarkTokenProtected),
            account,
            trackNonce,
            fnCalldata,
            _signingAuthorityPvtKey,
            expirationWindow,
            msgValue
        );
        _benchmarkTokenProtected.disperseTokens(recipients, amounts, cube3Payload);
        vm.stopBroadcast();
    }

    // utils

    function _setNonce() private {
        _nonce =
            uint256(keccak256(abi.encode(tx.origin, tx.origin.balance, block.number, block.timestamp, block.coinbase)));
    }

    function _randomBytes32() internal view returns (bytes32) {
        bytes memory seed = abi.encode(_nonce, block.timestamp, gasleft());
        return keccak256(seed);
    }

    function _randomUint256() internal view returns (uint256) {
        return uint256(_randomBytes32());
    }

    function _randomAddress() internal returns (address payable) {
        _setNonce();
        return payable(address(uint160(_randomUint256())));
    }

    function _sliceBytes(bytes memory _bytes, uint256 start, uint256 end) private returns (bytes memory) {
        require(_bytes.length >= end, "Slice end too high");

        bytes memory tempBytes = new bytes(end - start);
        for (uint256 i = 0; i < end - start; i++) {
            tempBytes[i] = _bytes[i + start];
        }
        return tempBytes;
    }

    function _encodePayload(bool trackNonce, uint256 nonce, uint256 expirationTimestamp, bytes memory signature)
        internal
        view
        returns (bytes memory)
    {
        // Construct the CubePayload
        // we don't need the verfied calldata, because the actual call data is used to reconstruct the hash that gets signed on-chain
        return abi.encode(
            Cube3SignatureModule.validateSignature.selector,
            signatureModule.moduleId(),
            expirationTimestamp,
            trackNonce, // whether to track the nonce
            nonce,
            signature
        );
    }

    function _createSignature(bytes memory encodedSignatureData, uint256 pvtKeyToSignWith)
        internal
        returns (bytes memory signature)
    {
        bytes32 signatureHash = keccak256(encodedSignatureData);
        bytes32 ethSignedHash = signatureHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvtKeyToSignWith, ethSignedHash);

        signature = abi.encodePacked(r, s, v);

        require(signature.length == 65, "invalid signature length");

        (address signedHashAddress, ECDSA.RecoverError error) = ethSignedHash.tryRecover(signature);
        if (error != ECDSA.RecoverError.NoError) {
            revert("No Matchies");
        }

        require(signedHashAddress == vm.addr(pvtKeyToSignWith), "signers dont match");
    }

    function _createPayload(
        address integration,
        address caller,
        bool shouldTrackNonce,
        bytes memory verifiedCalldata,
        uint256 signingAuthPvtKey,
        uint256 expirationWindow,
        uint256 msgValue
    ) internal returns (bytes memory) {

        bytes memory slicedCalldata = _sliceBytes(
            verifiedCalldata,
            0,
            verifiedCalldata.length - 320 - 32 // emptyPayload is 320 bytes in length
        );
        uint256 expirationTimestamp = block.timestamp + expirationWindow;
        uint256 nonce =
            shouldTrackNonce ? signatureModule.integrationUserNonce(address(_benchmarkTokenProtected), caller) + 1 : 0;

        // create the signature (ie what's usually handled by the risk API)
        bytes memory encodedSignatureData = abi.encodePacked(
            block.chainid, // chain id
            caller, // EOA / sender
            integration, // client contract
            address(signatureModule), // module contract address
            Cube3SignatureModule.validateSignature.selector, // the module fn's signature
            msgValue, // Eth value being sent
            nonce,
            expirationTimestamp, // expiration
            slicedCalldata // function calldata
        );

        bytes memory signature = _createSignature(encodedSignatureData, signingAuthPvtKey);
        bytes memory cubePayload = _encodePayload(shouldTrackNonce, nonce, expirationTimestamp, signature);
        return cubePayload;
    }

    function _generateRegistrarSignature(address integration, uint256 signingAuthPvtKey)
        internal
        returns (bytes memory)
    {
        (address integrationOrProxy, address integrationSelf) = ICube3Integration(integration).self();
        address integrationSecurityAdmin = ISecurityAdmin2Step(integration).securityAdmin();
        return _createSignature(
            abi.encodePacked(integrationOrProxy, integrationSelf, integrationSecurityAdmin, block.chainid),
            signingAuthPvtKey
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//         .-""-.
//        / .--. \
//       / /    \ \
//       | |    | |
//       | |.-""-.|
//      ///`.::::.`\
//     ||| ::/  \:: ;
//     ||; ::\__/:: ;
//      \\\ '::::' /
//       `=':-..-'`
//    https://duo.cash

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/// Simple helper contract for DuoCash withdrawals
contract SimpleWithdrawal is Initializable, Ownable {
    using SafeERC20 for IERC20;

    // Errors
    error InvalidParams();
    error NativeAssetWithdrawalFailed();

    constructor() initializer {
        // The singleton should not have a owner
        renounceOwnership();
    }

    function initialize(
        address _owner
    ) external initializer {
        _transferOwnership(_owner);
    }

    /// @notice Once unlocked this can be used to get full control over the locker
    /// @dev Changes the admin of the proxy to the specified address
    /// @param to the recipient of the withdrawal
    /// @param nativeAmount the native asset amount
    function withdraw(
        address payable to,
        uint256 nativeAmount,
        address[] memory erc20,
        uint256[] memory erc20Amounts,
        address[] memory erc721,
        uint256[] memory erc721Ids,
        address[] memory erc1155,
        uint256[] memory erc1155Ids,
        uint256[] memory erc1155Amounts
    ) external onlyOwner {
        // Make sure the params are correct
        if(
            erc20.length != erc20Amounts.length ||
            erc721.length != erc721Ids.length ||
            erc1155.length != erc1155Ids.length ||
            erc1155.length != erc1155Amounts.length
        ){
            revert InvalidParams();
        }

        // Withdraw ERC20s
        for(uint256 i; i< erc20.length; i++){
            IERC20(erc20[i]).safeTransfer(to, erc20Amounts[i]);
        }

        // Withdraw ERC721s
        for(uint256 i; i< erc721.length; i++){
            IERC721(erc721[i]).safeTransferFrom(address(this), to, erc721Ids[i]);
        }

        // Withdraw ERC1155s
        for(uint256 i; i< erc1155.length; i++){
            IERC1155(erc1155[i]).safeTransferFrom(address(this), to, erc1155Ids[i], erc1155Amounts[i], new bytes(0));
        }

        if(nativeAmount > 0){
            // Withdraw native asset    
            (bool succeed, bytes memory data) = to.call{value: nativeAmount}("");
            // Make sure the native asset was withdrawn succefully
            if(!succeed) revert NativeAssetWithdrawalFailed();
        }
    }
}
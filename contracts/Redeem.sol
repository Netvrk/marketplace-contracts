// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Redeem is AccessControl {
    bytes32 public constant WORKER_ROLE = keccak256("WORKER");

    /**
     * @dev Intitialize the contract
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(WORKER_ROLE, _msgSender());
    }

    //  Redeem Orders
    struct RedeemOrder {
        bytes32 id;
        address player;
        uint256 amount;
        bool executed;
        uint256 requestedTime;
    }

    RedeemOrder[] public redeemOrders;

    /**
     * @dev Request token redeem
     * @param player - Address of player
     * @param amount - Redeem amount
     * @return redeemOrder
     */
    function requestRedeem(address player, uint256 amount)
        public
        onlyRole(WORKER_ROLE)
        returns (RedeemOrder memory)
    {
        bytes32 orderId = keccak256(
            abi.encodePacked(
                block.timestamp,
                player,
                amount,
                redeemOrders.length
            )
        );

        RedeemOrder memory newRedeemOrder = RedeemOrder({
            id: orderId,
            player: player,
            amount: amount,
            executed: false,
            requestedTime: block.timestamp
        });

        redeemOrders.push(newRedeemOrder);

        return newRedeemOrder;
    }

    /**
     * @dev Execute the requested redeem order
     * @param index - Redeem index to execute
     */
    function executeRedeem(uint256 index)
        public
        onlyRole(WORKER_ROLE)
        returns (bool)
    {
        require(redeemOrders[index].executed == false, "ALREADY_REDEEMED");

        // TODO: Mint NRGY token.
        redeemOrders[index].executed = true;

        return true;
    }

    /**
     * @dev Get total size of redeem orders
     * @return RedeemLength
     */
    function getRedeemOrdersSize() public view returns (uint256) {
        return redeemOrders.length;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RedPacket {
 
    struct Packet {
        address token;
        address sender;
        uint256 total;
        uint256 quantity;
        string message;
        uint256 allowedCount;
    }

    struct Recipient {
        address target;
        uint256 amount;
    }

    uint256 private index = 1;
    address private immutable eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(uint256 => Packet) private packets;
    // The amount received by the user after opening the red packet
    mapping(uint256 => Recipient[]) public received;
    // allowe user open red packet
    // packet id -> user address -> allowed
    mapping(uint256 => mapping(address => bool)) allowed;

    event CreatePacket(uint256 id);
    event OpenPacket(uint256 id, address recipient, uint256 amount);

    function createPacket(
        address token,
        uint256 total,
        uint256 quantity,
        string calldata message,
        address[] calldata allowedList
    ) external payable returns (uint256) {
        if (token == eth) {
            require(total == msg.value, "insufficient amount");
        } else {
            require(
                IERC20(token).transferFrom(msg.sender, address(this), total),
                "insufficient amount"
            );
        }

        uint256 id = index;

        packets[id] = Packet({
            token: token,
            sender: msg.sender,
            total: total,
            quantity: quantity,
            message: message,
            allowedCount: allowedList.length
        });
        for (uint256 i = 0; i < allowedList.length; i++) {
            address recipient = allowedList[i];
            allowed[id][recipient] = true;
        }
        index += 1;

        emit CreatePacket(id);

        return id;
    }

    function getPacket(uint256 id)
        public
        view
        returns (Packet memory packet)
    {
        return packets[id];
    }

    function isAllowed(uint256 id, address recipient) public view returns (bool) {
        Packet memory packet = getPacket(id);
        
        if (packet.allowedCount == 0) {
            return true;
        } else {
            return allowed[id][recipient];
        }
    }

    function balanceOf(uint256 id) public view returns (uint256) {
        Packet memory packet = getPacket(id);
        Recipient[] memory _received = received[id];
        uint256 balance = packet.total;

        for (uint256 i = 0; i < _received.length; i++) {
            uint256 amount = _received[i].amount;
            balance = balance - amount;
        }

        return balance;
    }

    function generateAmount(uint256 total, uint256 quantity) private pure returns (uint256) {
        return total / quantity;
    }

    function openPacket(uint256 id) external {
        address recipient = msg.sender;
        uint256 balance = balanceOf(id);

        require(isAllowed(id, recipient), "not allowed");
        require(balance > 0, "insufficient balance");
        
        Packet memory packet = getPacket(id);
        uint256 amount = generateAmount(balance, packet.quantity);

        allowed[id][recipient] = false;
        received[id] = Recipient({ target: recipient, amount: amount });

        if (packet.token == eth) {
            payable(recipient).transfer(amount);
        } else {
            IERC20(packet.token).transfer(recipient, amount);
        }

        emit OpenPacket(id, recipient, amount);
    }
}

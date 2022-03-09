// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract P2EMarketPlace is Ownable, Pausable {
    using Address for address;

    IERC20 public acceptedToken;

    struct Order {
        // Order ID
        bytes32 id;
        // Owner of the NFT
        address seller;
        // NFT registry address
        address nftAddress;
        // Price (in wei) for the published item
        uint256 price;
        // Time when this sale ends
        uint256 expiresAt;
    }

    // From ERC721 registry assetId to Order (to avoid asset collision)
    mapping(address => mapping(uint256 => Order)) public orderByAssetId;

    // Fees
    address public feesCollector;
    uint256 public feesCollectorCutPerMillion;
    uint256 public publicationFeeInWei;

    bytes4 public constant ERC721_INTERFACE = bytes4(0x80ac58cd);

    // Order events
    event OrderCreated(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller,
        address nftAddress,
        uint256 priceInWei,
        uint256 expiresAt
    );

    event OrderSuccessful(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller,
        address nftAddress,
        uint256 totalPrice,
        address indexed buyer
    );

    event OrderCancelled(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller,
        address nftAddress
    );

    // Fee events
    event ChangedPublicationFee(uint256 publicationFee);
    event ChangedFeesCollectorCutPerMillion(uint256 feesCollectorCutPerMillion);
    event FeesCollectorSet(
        address indexed oldFeesCollector,
        address indexed newFeesCollector
    );

    /**
     * @dev Initialize this contract. Acts as a constructor
     * @param _feesCollector - fees collector
     * @param _acceptedToken - Address of the ERC20 accepted for this marketplace
     * @param _feesCollectorCutPerMillion - fees collector cut per million
     */
    constructor(
        address _acceptedToken,
        address _feesCollector,
        uint256 _feesCollectorCutPerMillion
    ) {
        require(_acceptedToken.isContract(), "INVALID_ACCEPTED_TOKEN");
        acceptedToken = IERC20(_acceptedToken);
        // Fee address init
        setFeesCollector(_feesCollector);
        // Fee init
        setFeesCollectorCutPerMillion(_feesCollectorCutPerMillion);
    }

    /**
     * @dev Sets the publication fee that's charged to users to publish items
     * @param _publicationFee - Fee amount in wei this contract charges to publish an item
     */
    function setPublicationFee(uint256 _publicationFee) external onlyOwner {
        publicationFeeInWei = _publicationFee;
        emit ChangedPublicationFee(publicationFeeInWei);
    }

    /**
     * @dev Sets the share cut for the fees collector of the contract that's
     *  charged to the seller on a successful sale
     * @param _feesCollectorCutPerMillion - fees for the collector
     */
    function setFeesCollectorCutPerMillion(uint256 _feesCollectorCutPerMillion)
        public
        onlyOwner
    {
        feesCollectorCutPerMillion = _feesCollectorCutPerMillion;

        require(
            feesCollectorCutPerMillion < 1000000,
            "FEES_NOT_BETWEEN_0_AND_999999"
        );

        emit ChangedFeesCollectorCutPerMillion(feesCollectorCutPerMillion);
    }

    /**
     * @notice Set the fees collector
     * @param _newFeesCollector - fees collector
     */
    function setFeesCollector(address _newFeesCollector) public onlyOwner {
        require(_newFeesCollector != address(0), "INVALID_FEES_COLLECTOR");

        emit FeesCollectorSet(feesCollector, _newFeesCollector);
        feesCollector = _newFeesCollector;
    }

    /**
     * @dev Creates a new order
     * @param nftAddress - Non fungible registry address
     * @param assetId - ID of the published NFT
     * @param priceInWei - Price in Wei for the supported coin
     * @param expiresAt - Duration of the order (in hours)
     */
    function createOrder(
        address nftAddress,
        uint256 assetId,
        uint256 priceInWei,
        uint256 expiresAt
    ) public whenNotPaused {
        _createOrder(nftAddress, assetId, priceInWei, expiresAt);
    }

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller or the contract owner
     * @param nftAddress - Address of the NFT registry
     * @param assetId - ID of the published NFT
     */
    function cancelOrder(address nftAddress, uint256 assetId)
        public
        whenNotPaused
    {
        _cancelOrder(nftAddress, assetId);
    }

    /**
     * @dev Executes the sale for a published NFT
     * @param nftAddress - Address of the NFT registry
     * @param assetId - ID of the published NFT
     * @param price - Order price
     */
    function executeOrder(
        address nftAddress,
        uint256 assetId,
        uint256 price
    ) public whenNotPaused {
        _executeOrder(nftAddress, assetId, price);
    }

    /**
     * @dev Creates a new order
     * @param nftAddress - Non fungible registry address
     * @param assetId - ID of the published NFT
     * @param priceInWei - Price in Wei for the supported coin
     * @param expiresAt - Duration of the order (in hours)
     */
    function _createOrder(
        address nftAddress,
        uint256 assetId,
        uint256 priceInWei,
        uint256 expiresAt
    ) internal {
        _requireERC721(nftAddress);

        address sender = _msgSender();

        IERC721 nftRegistry = IERC721(nftAddress);
        address assetOwner = nftRegistry.ownerOf(assetId);

        require(sender == assetOwner, "NOT_ASSET_OWNER");
        require(
            nftRegistry.getApproved(assetId) == address(this) ||
                nftRegistry.isApprovedForAll(assetOwner, address(this)),
            "CONTRACT_NOT_AUTHORIZED"
        );
        require(priceInWei > 0, "PRICE_LESS_THAN_ZERO");
        require(expiresAt > block.timestamp + 1 minutes, "INVALID_EXPIRES_AT");

        bytes32 orderId = keccak256(
            abi.encodePacked(
                block.timestamp,
                assetOwner,
                assetId,
                nftAddress,
                priceInWei
            )
        );

        orderByAssetId[nftAddress][assetId] = Order({
            id: orderId,
            seller: assetOwner,
            nftAddress: nftAddress,
            price: priceInWei,
            expiresAt: expiresAt
        });

        // Check if there's a publication fee and
        // transfer the amount to marketplace owner
        if (publicationFeeInWei > 0) {
            require(
                acceptedToken.transferFrom(
                    sender,
                    feesCollector,
                    publicationFeeInWei
                ),
                "TRANSFER_FAILED"
            );
        }

        emit OrderCreated(
            orderId,
            assetId,
            assetOwner,
            nftAddress,
            priceInWei,
            expiresAt
        );
    }

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller or the contract owner
     * @param nftAddress - Address of the NFT registry
     * @param assetId - ID of the published NFT
     */
    function _cancelOrder(address nftAddress, uint256 assetId)
        internal
        returns (Order memory)
    {
        address sender = _msgSender();
        Order memory order = orderByAssetId[nftAddress][assetId];

        require(order.id != 0, "INVALID_ORDER");
        require(
            order.seller == sender || sender == owner(),
            "UNAUTHORIZED_USER"
        );

        bytes32 orderId = order.id;
        address orderSeller = order.seller;
        address orderNftAddress = order.nftAddress;
        delete orderByAssetId[nftAddress][assetId];

        emit OrderCancelled(orderId, assetId, orderSeller, orderNftAddress);

        return order;
    }

    /**
     * @dev Executes the sale for a published NFT
     * @param nftAddress - Address of the NFT registry
     * @param assetId - ID of the published NFT
     * @param price - Order price
     */
    function _executeOrder(
        address nftAddress,
        uint256 assetId,
        uint256 price
    ) internal returns (Order memory) {
        _requireERC721(nftAddress);

        address sender = _msgSender();

        IERC721 nftRegistry = IERC721(nftAddress);

        Order memory order = orderByAssetId[nftAddress][assetId];

        require(order.id != 0, "ASSET_NOT_FOR_SALE");

        require(order.seller != address(0), "INVALID_SELLER");
        require(order.seller != sender, "SENDER_IS_SELLER");
        require(order.price == price, "PRICE_MISMATCH");
        require(block.timestamp < order.expiresAt, "ORDER_EXPIRED");
        require(
            order.seller == nftRegistry.ownerOf(assetId),
            "SELLER_NOT_OWNER"
        );

        delete orderByAssetId[nftAddress][assetId];

        // Fees collector share

        uint256 feesCollectorShareAmount = (price *
            feesCollectorCutPerMillion) / 1000000;
        uint256 totalFeeCollectorShareAmount = feesCollectorShareAmount;

        if (totalFeeCollectorShareAmount > 0) {
            require(
                acceptedToken.transferFrom(
                    sender,
                    feesCollector,
                    totalFeeCollectorShareAmount
                ),
                "TRANSFER_FEES_TO_COLLECTOR_ERROR"
            );
        }

        // Transfer sale amount to seller
        require(
            acceptedToken.transferFrom(
                sender,
                order.seller,
                price - feesCollectorShareAmount
            ),
            "TRANSFER_AMOUNT_TO_SELLER_ERROR"
        );

        // Transfer asset owner
        nftRegistry.safeTransferFrom(order.seller, sender, assetId);

        emit OrderSuccessful(
            order.id,
            assetId,
            order.seller,
            nftAddress,
            price,
            sender
        );

        return order;
    }

    function _requireERC721(address nftAddress) internal view {
        require(nftAddress.isContract(), "INVALID_NFT_ADDRESS");

        IERC721 nftRegistry = IERC721(nftAddress);
        require(
            nftRegistry.supportsInterface(ERC721_INTERFACE),
            "INVALID_ERC721_IMPLEMENTATION"
        );
    }

    function setPaused(bool _pause) external onlyOwner {
        _paused = _pause;
    }
}

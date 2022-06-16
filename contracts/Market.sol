// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IRoyaltiesManager.sol";

contract MarketPlace is
    UUPSUpgradeable,
    ContextUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;

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

    IRoyaltiesManager public royaltiesManager;
    uint256 public royaltiesCutPerMillion;

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
    event ChangedFeesCollectorCutPerMillion(uint256 feesCollectorCutPerMillion);
    event FeesCollectorSet(
        address indexed oldFeesCollector,
        address indexed newFeesCollector
    );
    event ChangedRoyaltiesCutPerMillion(uint256 royaltiesCutPerMillion);
    event RoyaltiesManagerSet(
        IRoyaltiesManager indexed oldRoyaltiesManager,
        IRoyaltiesManager indexed newRoyaltiesManager
    );

    /**
     * @dev Initialize this contract. Acts as a constructor
     * @param _feesCollector - fees collector
     * @param _acceptedToken - Address of the ERC20 accepted for this marketplace
     * @param _feesCollectorCutPerMillion - fees collector cut per million
     */
    function initialize(
        address _acceptedToken,
        address _feesCollector,
        uint256 _feesCollectorCutPerMillion,
        IRoyaltiesManager _royaltiesManager,
        uint256 _royaltiesCutPerMillion
    ) public initializer {
        require(_acceptedToken.isContract(), "INVALID_ACCEPTED_TOKEN");

        __UUPSUpgradeable_init();
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        acceptedToken = IERC20(_acceptedToken);

        // Fee address init
        setFeesCollector(_feesCollector);
        setRoyaltiesManager(_royaltiesManager);

        // Fee init
        setRoyaltiesCutPerMillion(_royaltiesCutPerMillion);
        setFeesCollectorCutPerMillion(_feesCollectorCutPerMillion);
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
     * @dev Sets the share cut for the royalties that's
     *  charged to the seller on a successful sale
     * @param _royaltiesCutPerMillion - fees for royalties
     */
    function setRoyaltiesCutPerMillion(uint256 _royaltiesCutPerMillion)
        public
        onlyOwner
    {
        royaltiesCutPerMillion = _royaltiesCutPerMillion;

        require(
            feesCollectorCutPerMillion + royaltiesCutPerMillion < 1000000,
            "TOTAL_FEES_MUST_BE_BETWEEN_0_AND_999999"
        );

        emit ChangedRoyaltiesCutPerMillion(royaltiesCutPerMillion);
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
     * @notice Set the royalties manager
     * @param _newRoyaltiesManager - royalties manager
     */
    function setRoyaltiesManager(IRoyaltiesManager _newRoyaltiesManager)
        public
        onlyOwner
    {
        require(
            address(_newRoyaltiesManager).isContract(),
            "INVALID_ROYALTIES_MANAGER"
        );

        emit RoyaltiesManagerSet(royaltiesManager, _newRoyaltiesManager);
        royaltiesManager = _newRoyaltiesManager;
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
    ) public whenNotPaused nonReentrant {
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
        nonReentrant
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
    ) public whenNotPaused nonReentrant {
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

        uint256 feesCollectorShareAmount;
        uint256 royaltiesShareAmount;
        address royaltiesReceiver;

        // Royalties share
        if (royaltiesCutPerMillion > 0) {
            royaltiesShareAmount = (price * royaltiesCutPerMillion) / 1000000;

            (bool success, bytes memory res) = address(royaltiesManager)
                .staticcall(
                    abi.encodeWithSelector(
                        royaltiesManager.getRoyaltiesReceiver.selector,
                        address(nftRegistry),
                        assetId
                    )
                );

            if (success) {
                (royaltiesReceiver) = abi.decode(res, (address));
                if (royaltiesReceiver != address(0)) {
                    require(
                        acceptedToken.transferFrom(
                            sender,
                            royaltiesReceiver,
                            royaltiesShareAmount
                        ),
                        "TRANSFER_FEES_TO_ROYALTIES_RECEIVER_FAILED"
                    );
                }
            }
        }

        // Fees collector share
        {
            feesCollectorShareAmount =
                (price * feesCollectorCutPerMillion) /
                1000000;
            uint256 totalFeeCollectorShareAmount = feesCollectorShareAmount;

            if (royaltiesShareAmount > 0 && royaltiesReceiver == address(0)) {
                totalFeeCollectorShareAmount += royaltiesShareAmount;
            }

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
        }

        // Transfer sale amount to seller
        require(
            acceptedToken.transferFrom(
                sender,
                order.seller,
                price - royaltiesShareAmount - feesCollectorShareAmount
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

    // UUPS proxy function
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _requireERC721(address nftAddress) internal view {
        require(nftAddress.isContract(), "INVALID_NFT_ADDRESS");

        IERC721 nftRegistry = IERC721(nftAddress);
        require(
            nftRegistry.supportsInterface(ERC721_INTERFACE),
            "INVALID_ERC721_IMPLEMENTATION"
        );
    }

    function setPaused(bool _contractPaused) external onlyOwner {
        if (_contractPaused) {
            _unpause();
        } else {
            _pause();
        }
    }
}

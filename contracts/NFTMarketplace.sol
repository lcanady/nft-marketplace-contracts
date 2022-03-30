//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./NFT.sol";

contract NFTMarketplace is Ownable, ReentrancyGuard, IERC721Receiver {
    uint256 private serviceFee = 750;

    struct ItemForSale {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool forSale;
    }

    mapping(address => uint256) private royalties;
    mapping(uint256 => ItemForSale) private itemsForSale;
    using Counters for Counters.Counter;

    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    event ItemAdded(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    event ItemSold(
        uint256 indexed id,
        address seller,
        address buyer,
        uint256 price
    );

    event SaleCanceled(
        uint256 indexed id,
        address seller,
        uint256 tokenId,
        uint256 price
    );

    /**
     * @notice Set the Service fee for the marketplace.
     */
    function setServiceFee(uint256 percent) public onlyOwner {
        serviceFee = percent;
    }

    /**
     * @notice Get the Service fee.
     */
    function getServiceFee() public view returns (uint256) {
        return serviceFee;
    }

    /**
     * @notice Set the roytalty percentage for an NFT contract.
     * @param nftContract The address of the contract to work with.
     * @param percent the royalty percentage to take.
     */
    function setRoyalties(address nftContract, uint256 percent) public {
        require(
            NFT(nftContract).owner() == msg.sender,
            "You don't own that contract."
        );
        royalties[nftContract] = percent;
    }

    /**
     * @notice get the royalty percentage for a given contract.
     * @param nftContract The contract to get the percentage for.
     */
    function getRoyalties(address nftContract) public view returns (uint256) {
        return royalties[nftContract];
    }

    /**
     * @notice Add an NFT to the marketplace.
     * @param nftContract The contract of the NFT to add.
     * @param tokenId The NFT's identifying ID on the contract added.
     * @param price The price to sell the NFT for.
     * @dev The price must at least be as much as the price listing fee.
     */
    function addItemToMarket(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");

        _itemsSold.increment();
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        itemsForSale[itemId] = ItemForSale(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            true
        );

        NFT(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

        emit ItemAdded(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price
        );
    }

    /**
     * @notice Get an item entry from the marketplace.
     * @param itemId The id of the sale.
     */
    function getItem(uint256 itemId) public view returns (ItemForSale memory) {
        uint256 count = _itemIds.current();
        require(itemId <= count, "That idem doesn't exist.");
        return itemsForSale[itemId];
    }

    /**
     * @notice Cancel a sale.
     * @param itemId The sale Id.
     */
    function cancelSaleFromMarket(uint256 itemId) public {
        require(itemsForSale[itemId].forSale == true, "Item is not for sale.");
        require(
            itemsForSale[itemId].seller == msg.sender,
            "This isn't your sale."
        );

        NFT(itemsForSale[itemId].nftContract).transferFrom(
            address(this),
            itemsForSale[itemId].seller,
            itemsForSale[itemId].tokenId
        );

        itemsForSale[itemId].forSale = false;

        emit SaleCanceled(
            itemId,
            itemsForSale[itemId].seller,
            itemsForSale[itemId].tokenId,
            itemsForSale[itemId].price
        );
    }

    /**
     * @notice Buy an item from the market.
     * @param itemId The Sale item to buy.
     */
    function buyItem(uint256 itemId) public payable nonReentrant {
        uint256 price = itemsForSale[itemId].price;
        uint256 tokenId = itemsForSale[itemId].tokenId;
        address nftContract = itemsForSale[itemId].nftContract;
        address seller = itemsForSale[itemId].seller;
        address contractOwner = NFT(nftContract).owner();

        require(msg.value >= price, "Ammount too low.");
        require(itemsForSale[itemId].forSale == true, "Item is not for sale.");

        itemsForSale[itemId].owner = payable(msg.sender);
        itemsForSale[itemId].forSale = false;
        uint256 creatorShare = (msg.value * royalties[nftContract]) / 1e4;
        uint256 houseShare = (msg.value * serviceFee) / 1e4;

        payable(contractOwner).transfer(creatorShare);
        // payable(address(this)).transfer(houseShare);
        payable(seller).transfer(msg.value - houseShare);

        NFT(nftContract).transferFrom(address(this), msg.sender, tokenId);

        emit ItemSold(
            itemId,
            itemsForSale[itemId].seller,
            itemsForSale[itemId].owner,
            price
        );
    }

    function withdrawl() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02;
    }
}

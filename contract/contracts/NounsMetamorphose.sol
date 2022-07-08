// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

struct LayerData {
    uint8 color;
    uint8 body;
    uint8 initColor;
    uint8 initBody;
    uint8 metCount;
}

contract NounsMetamorphose is ERC721Enumerable, Ownable, Pausable  {
    using Strings for uint8;
    using Strings for uint256;

    // constant
    uint256 constant private MAX_SUPPLY = 1024;
    uint256 constant private CLAIM_MAX_PER_WALLET = 5;
    uint256 constant private PUBLIC_COST = 0.00 ether;

    // layerData
    mapping(uint256 => LayerData) private layerData;

    // svg
    bool private frozen = false;
    string private svgHead;
    string private svgDef;
    string[] private svgColorPallet;
    string[] private svgBody;

    // user
    mapping(address => uint256) private addrClaimed;

    constructor() ERC721("NounsMetamorphose", "NM") {}

    // modifier
    modifier nonFrozen() {
        require(!frozen, "Data is frozen");
        _;
    }
    
    modifier isExist(uint256 _tokenId) {
        require(_exists(tokenId), "URI query for nonexistent token");
        _;
    }

    // withdraw
    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    // pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    // mint
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        uint256 cost = PUBLIC_COST * _mintAmount;
        mintCheck(_mintAmount, supply, cost);
  
        for (uint256 i = 1; i <= _mintAmount; i++) {
            initLayerData(supply + i);
            _safeMint(msg.sender, supply + i);
            addrClaimed[msg.sender]++;
        }
    }

    function ownerMint(address _address, uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();

        for (uint256 i = 1; i <= _mintAmount; i++) {
            initLayerData(supply + i);
            _safeMint(msg.sender, supply + i);
            safeTransferFrom(msg.sender, _address, supply + i);
        }
    }

    function mintCheck(uint256 _mintAmount, uint256 _supply, uint256 _cost) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(_supply + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(addrClaimed[msg.sender] + _mintAmount <= CLAIM_MAX_PER_WALLET, "Already claimed max");
        require(msg.value >= _cost, "Not enough funds");
    }


    // layerData
    function initLayerData(uint256 _tokenId) private {
        LayerData memory data;
        data.color = uint8(rand(svgColorPallet.length));
        data.body = uint8(rand(svgBody.length));
        data.initColor = data.color;
        data.initBody = data.body;
        data.metCount = 0;
        layerData[_tokenId] = data;
    }

    function Metamorphose(uint256 _tokenId) external isExist(_tokenId) {
        require(_exists(tokenId), "URI query for nonexistent token");
        require(msg.sender == ownerOf(_tokenId));

        LayerData storage data = layerData[_tokenId];
        data.color = uint8(rand(svgColorPallet.length));
        data.body = uint8(rand(svgBody.length));
        data.metCount++;
    }

    function ResetMetamorphose(uint256 _tokenId) external isExist(_tokenId) {
        require(_exists(tokenId), "URI query for nonexistent token");
        require(msg.sender == ownerOf(_tokenId));

        LayerData storage data = layerData[_tokenId];
        data.color = data.initColor;
        data.body = data.initColor;
        data.metCount = 0;
    }


    // svg
    function freeze() external onlyOwner {
        frozen = true;
    }

    function setSvgHead(string calldata _head) external onlyOwner {
        require(!frozen, "Data is frozen");
        svgHead = _head;
    }

    function setSvgDef(string calldata _def) external onlyOwner {
        require(!frozen, "Data is frozen");
        svgDef = _def;
    }

    function setColorPallet(string[] memory _colors) external onlyOwner {
        require(!frozen, "Data is frozen");
        for (uint256 i = 0; i < _colors.length; i++) {
            svgColorPallet.push(_colors[i]);
        }
    }

    function setBody(string[] memory _bodies) external onlyOwner {
        require(!frozen, "Data is frozen");
        for (uint256 i = 0; i < _bodies.length; i++) {
            svgBody.push(_bodies[i]);
        }
    }


    // tokenURI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(getMetadata(tokenId))
                )
            );
    }

    function getMetadata(uint256 _tokenId) private view returns (bytes memory) {
        LayerData memory data = layerData[_tokenId];
        string memory color = svgColorPallet[data.color];

        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "color", "value": "',
            color,
            '"}, {"trait_type": "MetamorphoseCount", "value": "',
            data.metCount.toString(),
            '"}'
        );

        bytes
            memory description = 'NounsMetamorphose #';
        return
            abi.encodePacked(
                '{"name": "NounsMetamorphose #',
                _tokenId.toString(),
                '", "description": "',
                description + _tokenId.toString(),
                '", "image": "data:image/svg+xml;base64,',
                Base64.encode(getSvg(_tokenId)),
                '", "attributes": [',
                attributes,
                "]}"
            );
    }

    function getSvg(uint256 _tokenId) private view returns (bytes memory) {
        LayerData memory data = layerData[_tokenId];
        string memory color = svgColorPallet[data.color];
        string memory body = svgBody[data.body];

        string memory styles = string(abi.encodePacked(
            "<style> .base { fill: ",
            color,
            "; }",
            "</style>"
        ));

        string memory ownerName = string(abi.encodePacked(
            "<text x='20' y='20' font-family='Verdana' font-size='24'>",
            substring(Strings.toHexString(uint160(ownerOf(_tokenId)), 20), 0, 10),
            "</text>"
        ));

        return bytes(abi.encodePacked(svgHead, styles, svgDef, body, ownerName, "</svg>"));
    }

    function rand(uint256 mod) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % mod;
    }

    function substring(string memory _str, uint _startIndex, uint _endIndex) private pure returns (string memory ) {
        bytes memory strBytes = bytes(_str);
        bytes memory result = new bytes(_endIndex - _startIndex);
        for(uint i = _startIndex; i < _endIndex; i++) {
            result[i - _startIndex] = strBytes[i];
        }
        return string(result);
    }
}
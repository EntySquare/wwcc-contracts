// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0 <0.9.0;


contract NFTSWAP {
   struct PairPool{
        address token1;
        address token2;
        uint256 token1Pool;
        uint256 token2Pool;
        bool used;
    }
    uint256  index;
    address  owner;
    mapping (bytes32 => PairPool) pair;
    mapping (uint256 => bytes32) pairKeyList;
    event Transfer(address owner,address spender,uint256 value);
     event Approval(address owner,address spender,uint256 value);
     /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        address holder)  public{
        index = 0 ;                         // Set the symbol for display purposes
        owner = holder;
    }
    function set_Pair(
    address token1,
    address token2
    ) external  returns (bytes32) {
       string memory sToken1 = addressToString(token1);
       string memory sToken2 = addressToString(token2);
       string memory s = strConcat(sToken1,sToken2);
       bytes32 pairKey = keccak256(abi.encodePacked(s));
       if(contains(pairKey)) { 
            revert("pair exist");
       }else{
           if (stringCompare(sToken1,sToken2)){
               revert("same token");
           }
           pair[pairKey].used = true;
           pair[pairKey].token1 = token1;
           pair[pairKey].token2 = token2;
           pair[pairKey].token1Pool = 0;
           pair[pairKey].token2Pool = 0;
           pairKeyList[index] = pairKey;
           index ++ ;
       }
       return pairKey;
    }
    function getPair(bytes32 pairKey) external view returns (address token1,address token2,uint256 token1Pool,uint256 token2Pool){
        if(!contains(pairKey)) { 
            revert("not exist");
        }else{
            return (pair[pairKey].token1,pair[pairKey].token2,pair[pairKey].token1Pool,pair[pairKey].token2Pool);
        }
    }
    function contains(bytes32 pairKey) internal view returns (bool) {
            return pair[pairKey].used;
    }
    function strConcat(string memory _a,string memory _b) internal pure returns (string memory){
            bytes memory _ba = bytes(_a);
            bytes memory _bb = bytes(_b);
            string memory ret = new string(_ba.length + _bb.length);
            bytes memory bret = bytes(ret);
            uint k = 0;
            for(uint i = 0;i < _ba.length;i++) bret[k++] = _ba[i];
            for(uint i = 0;i < _bb.length;i++) bret[k++] = _bb[i];
            return string(ret);
        }
    function addressToString(address a) internal pure returns(string memory){
            return toString(abi.encodePacked(a));
    }
    function uint256ToString(uint256 u) internal pure returns(string memory){
            return toString(abi.encodePacked(u));
    }
    function bytes32ToString(bytes32 b) internal pure returns(string memory){
            return toString(abi.encodePacked(b));
     }
    function toString(bytes memory data) internal pure returns(string memory){
            bytes memory alphabet = "0123456789abcdef";
            bytes memory str = new bytes(2 + data.length * 2);
            str[0] = "0";
            str[1] = "x";
            for(uint i =0;i < data.length;i++){
                str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
                str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
            }
            return string(str);
    }
    function stringCompare(string memory a, string memory b) internal returns(bool){
        if (bytes(a).length != bytes(b).length){
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }
}
   
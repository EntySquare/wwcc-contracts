// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0 <0.9.0;

import "./safemath.sol";
contract WCPOOL {
   //single Pool struct 
   struct WcPool{
        string home;
        string visit;
        string rounds;
        uint256 wPool;
        uint256 dPool;
        uint256 lPool;
        uint256 sPool;
        uint256 basal;
        bool decided;
        bool used;
        bool finished;
    }
    //pool's base info to show
    struct PoolViewInfo{
        uint256 wPool;
        uint256 dPool;
        uint256 lPool;
        uint256 sPool;
        uint256 basal;
    }
    //all score pool struct
    struct AllScorePool{
        JoinerPicking[] separateBet;
        bytes32  poolKey;
    }
    //all picking info struct
    struct JoinerAllPicking{
        JoinerPicking[] separateBet;
        address  joiner;
    }
    //single picking struct
    struct JoinerPicking{
        uint256 weight;
        uint256 kind;
        uint256 homeScore;
        uint256 visitScore;
        address  joiner;
        string  pickingKey;
        bool finished;
    }
    using SafeMath for uint256;
    address owner;
    // basal last in contract
    uint256 nextBasalLast;
    //vote tickets for this address
    mapping (address => uint256) voteAmount;
    //all pools
    mapping (bytes32 => WcPool) WcPools;
    //all score pool info  in single pool
    mapping (bytes32 => AllScorePool) allScorePoolInfo;
    //singl score pool info  in single pool
    mapping (string => uint256) singleScorePool;
    //all picking info for this joiner
    mapping (address => JoinerAllPicking) joinerAllPicking;
    event Received(address, uint);
     /* Initializes contract with holder and  first basal you want to inject */
    constructor(
        address holder,uint256 firstBasal)  public{
        owner = holder;
        nextBasalLast = firstBasal;
        // nextWDLPoolAmount = 0;
        // nextScorePoolAmount = 0;
    }
    //manager set pool without basal
    function Set_Pool(
    string memory home,
    string memory visit,
    string memory rounds,
    bool decided
    ) external onlyManager returns (bytes32) {
       string memory s1 = strConcat(home,visit);
       string memory s2 = strConcat(s1,rounds);
       bytes32 poolKey = keccak256(abi.encodePacked(s2));
       if(contains(poolKey)) { 
            revert("pair exist");
       }else{
           WcPools[poolKey].used = true;
           WcPools[poolKey].home = home;
           WcPools[poolKey].visit = visit;
           WcPools[poolKey].rounds = rounds;
           WcPools[poolKey].wPool = 0;
           WcPools[poolKey].dPool = 0;
           WcPools[poolKey].lPool = 0;
           WcPools[poolKey].sPool = 0;
           WcPools[poolKey].basal = 0;
           WcPools[poolKey].decided = decided;
           WcPools[poolKey].finished = false;

       }
       return poolKey;
    }
    //joiner pick
    function Picking(address joiner,uint256 weight,bytes32 poolKey,uint256 homeScore,uint256 visitScore,uint256 kind) external returns(bool){
        if(!contains(poolKey)) { 
            revert("pool not exist");
       }else{
           if(voteAmount[joiner]<weight){
               revert("not enough voteAmount");
           }
           WcPool memory pool = WcPools[poolKey];
           string  memory si = strConcat(uint256ToString(homeScore),uint256ToString(visitScore));
           string  memory pickingKey = strConcat(bytes32ToString(poolKey),si);
           JoinerPicking memory jp = JoinerPicking(weight,kind,homeScore,visitScore,joiner,pickingKey,false);
           allScorePoolInfo[poolKey].poolKey = poolKey;
           allScorePoolInfo[poolKey].separateBet.push(jp); 
           joinerAllPicking[joiner].joiner = joiner;
           allScorePoolInfo[poolKey].separateBet.push(jp); 
            if (kind == 2){
              pool.sPool += weight;
              singleScorePool[pickingKey] += weight;
            }
            else if(kind == 3){
                pool.wPool += weight;
            }else if (kind == 1){
                pool.dPool += weight;
            }else {
                pool.lPool += weight;
            }
            voteAmount[joiner] -= weight;
           
       }
       return true;
    }
    //manager set basal in single pool by poolkey
    function Set_Basal(bytes32 poolKey,uint256 basal) external onlyManager  returns (bool){
        if(!contains(poolKey)) { 
            revert("pool not exist");
        }else{
           WcPool memory pool = WcPools[poolKey];
           if (pool.basal > 0){
               revert("pool basal has been set");
           }
           if (nextBasalLast > basal){
               revert("not enough basal");
           }
           pool.basal += basal;
           nextBasalLast -=  basal;
           return true;
        }
    }
    //manager withdraw pool's benefit
    function Withdrawal(address toAddress,bytes32 poolKey) external onlyManager payable returns (bool){
           if(!contains(poolKey)) { 
                revert("pool not exist");
           }else{
                WcPool memory pool = WcPools[poolKey];
                uint256 expect = (pool.wPool+pool.lPool+pool.dPool+pool.sPool + pool.basal).div(10);
                if (pool.finished = true){
                    address payable toAddress_address = payable(toAddress);
                    toAddress_address.transfer(expect);
                }else{
                    revert("pool has not finished");
                }               
           }
           return true;
    }
    //manager withdraw joiner's vote tickets for joiner
    function voteWithdrawal(address joiner,uint256 amount) external onlyManager payable returns (bool){
        if(voteAmount[joiner] >= amount && voteAmount[joiner] >= 0){
            address payable toAddress_address = payable(joiner);
            toAddress_address.transfer(voteAmount[joiner]);
        }else{
            revert("not enough voteAmount");
        }
        return true;
    }
    //manager check single pool's expect benefit by poolkey
    function CheckExpect(bytes32 poolKey) external onlyManager view  returns (uint256){
        if(!contains(poolKey)) { 
            revert("pool not exist");
        }else{
           WcPool memory pool = WcPools[poolKey];
           uint256 expect = (pool.wPool+pool.lPool+pool.dPool+pool.sPool + pool.basal).div(10);
           return expect;
        }
    }
    //manager check single pool's basal last in contract
    function CheckBasal() external onlyManager view  returns (uint256){
           return nextBasalLast;
    }
    //result settlement and loop each joiner in this to handle it
    function Award(bytes32 poolKey,uint256 homeScore,uint256 visitScore,uint256 result)  external onlyManager  payable returns(bool){
        if(!contains(poolKey)) { 
            revert("pool not exist");
       }else{
           WcPool memory pool = WcPools[poolKey];
           if (pool.finished=true){
               revert("pool has finished");
           }
           JoinerPicking[] memory separateBets = allScorePoolInfo[poolKey].separateBet;
           uint256 allRewardAmount = 0;
           nextBasalLast += (pool.sPool + pool.wPool+pool.lPool+pool.dPool + pool.basal.div(2)).div(20);
        //    uint256 wdls =pool.sPool+pool.wPool+pool.lPool+pool.dPool;
        //    uint256 serviceAmount = wdls.mul(15).div(100);
                for (
                uint j = 0;
                j <= separateBets.length-1;
                j ++
                ){
                  if(separateBets[j].finished = false){
                      if(separateBets[j].kind==2){
                          allRewardAmount = (pool.sPool + pool.basal.div(2)).mul(85).div(100);
                      if (separateBets[j].homeScore==homeScore && separateBets[j].visitScore==visitScore){
                          uint256 singleScorePoolAmount = singleScorePool[separateBets[j].pickingKey];
                          uint256 rewardAmount = allRewardAmount * separateBets[j].weight /  singleScorePoolAmount;
                          //reward
                        //   address payable joiner_address = payable(separateBets[j].joiner);
                        //   joiner_address.transfer(rewardAmount);
                        //   separateBets[j].finished = true;
                          //return voteAmount
                          voteAmount[separateBets[j].joiner] += rewardAmount;
                          separateBets[j].finished = true;

                          
                      }
                    }else{
                      if(separateBets[j].kind==result){
                          allRewardAmount = (pool.wPool+pool.lPool+pool.dPool+ pool.basal.div(2)).mul(85).div(100);
                          uint256 pickPoolAmount = 0;
                          if (separateBets[j].kind == 0){
                              pickPoolAmount = pool.lPool.mul(85).div(100);
                          }
                          if (separateBets[j].kind == 1){
                              pickPoolAmount = pool.dPool.mul(85).div(100);
                          }
                          if (separateBets[j].kind == 3){
                              pickPoolAmount = pool.wPool.mul(85).div(100);
                          }
                          uint256 rewardAmount = allRewardAmount * separateBets[j].weight /  pickPoolAmount;
                          //reward
                        //   address payable joiner_address = payable(separateBets[j].joiner);
                        //   joiner_address.transfer(rewardAmount);
                        //   separateBets[j].finished = true;
                          //return voteAmount
                          voteAmount[separateBets[j].joiner] += rewardAmount;
                          separateBets[j].finished = true;
                      }
                    }
                  }  
                }
                pool.finished = true;
                // address payable owner_address = payable(owner);
                // owner_address.transfer(serviceAmount);
       }
       return true;
    }
    //view pool's base info by exact poolkey
    function getPool(bytes32 poolKey) external view returns (string memory vs,string memory rounds,PoolViewInfo memory viewInfo){
        if(!contains(poolKey)) { 
            revert("not exist");
        }else{
            string  memory hv = strConcat(WcPools[poolKey].home," vs ");
            vs = strConcat(hv,WcPools[poolKey].visit);
            PoolViewInfo memory vi = PoolViewInfo(WcPools[poolKey].wPool,
            WcPools[poolKey].dPool,
            WcPools[poolKey].lPool,
            WcPools[poolKey].sPool,
            WcPools[poolKey].basal);
            return (vs,
            WcPools[poolKey].rounds,
            vi);
        }
    }


    //-----internal function------
    //contains or not
    function contains(bytes32 poolKey) internal view returns (bool) {
            return WcPools[poolKey].used;
    }

    //concat two string
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
    //transfer function
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
    //compare two string
    function stringCompare(string memory a, string memory b) internal pure returns(bool){
        if (bytes(a).length != bytes(b).length){
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }
    // @notice only manager can do in this condition
    modifier onlyManager() { 
        require(
            msg.sender == owner,
            "Only owner can call this."
        );
        _;
    }
    //receive bnb token and give user vote ticket
    receive() external payable {
         if(msg.sender != owner){
           voteAmount[msg.sender] += msg.value;
           emit Received(msg.sender, msg.value);
         }else{

         }
   }
}
   
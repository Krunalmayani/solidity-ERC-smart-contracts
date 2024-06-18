// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity( address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDEXFactory { 
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function approve(address spender, uint value) external returns (bool);
}

contract BattleInfinity is Ownable {
    using SafeMath for uint256;

    uint256 internal _totalSupply = 10000000000 * (10**18);
 
    address public pinkAntiBot_  = 0xBec5000E7351c977fD8cad3c3caD9E7d3DEf8F5f;
    address public pancakeRouterAddress = address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

    mapping (address => mapping (address => uint))  public  allowance;

    IDEXRouter public router;
    address public pair;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    address payable ContractAddress;
    address token1 = 0x325BdB28E1DaF378949B23ACc7D3BF5D88b0C4F7;
    address token2 = 0x67cf361fd56cA17E2e0bC8A497fBa208060eE628;
    // uint256 token1Amount =150000;
    // uint256 token2Amount =100000;
    event  Approval(address indexed src, address indexed guy, uint wad);

    
    receive() external payable { }

    constructor() {
        router = IDEXRouter(pancakeRouterAddress);
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());
    
        balances[address(this)] = 10000;
        balances[_msgSender()] = _totalSupply -10000;
    }

    function addLiquidityEx() public  {
        // _addLiquidityBusd(100000,150000);
        swapTokensForBNB(100000);
    }

    
    function swapTokensForBNB(uint256 tokenAmount) public {
        // generate the uniswap  pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        IDEXFactory(router.factory()).approve(address(this), tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 60
        );
    }

    function _addLiquidityBusd(uint256 token1Amount, uint256 token2Amount) private {
        router.addLiquidity(
            token1, token2,
            token1Amount,
            token2Amount,
            0, 0,
            _msgSender(),
            block.timestamp
        );
    }
    
}
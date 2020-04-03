pragma solidity 0.6.2;

import './SafeMath.sol';
import './ERC223ReceivingContract.sol';
import './ERC20.sol';
import './ERC223.sol';

contract ErbaToken is StandardToken
{
	string public name = "Erba Cultivation, LLC";
	string public symbol = "ERB";
	uint8 public constant decimals = 18;
	uint public constant DECIMALS_MULTIPLIER = 10**uint(decimals);

	constructor(address _owner) public
	{
		totalSupply = 10000000 * DECIMALS_MULTIPLIER;
		balances[_owner] = totalSupply;
	  	emit Transfer(address(0), _owner, totalSupply);
	}
}

contract StandardToken is ERC20, ERC223
{
	using SafeMath for uint256;

	uint256 public totalSupply;

	mapping (address => uint256) internal balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	event Burn(address indexed burner, uint256 value);

	function transfer(address _to, uint256 _value) external override returns (bool)
	{
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf (address _owner) public override view returns (uint256 balance)
	{
		return balances[_owner];
	}

	function transferFrom(address _from, address _to, uint256 _value) external override returns (bool)
	{
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) external override returns (bool)
	{
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public override view returns (uint256)
	{
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint256 _addedValue) external returns (bool)
	{
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) external returns (bool)
	{
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue)
		{
			allowed[msg.sender][_spender] = 0;
		}
		else
		{
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function transfer(address _to, uint256 _value, bytes calldata _data) external override
	{
		require(_value > 0 );
		if(isContract(_to))
		{
			ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
			receiver.tokenFallback(msg.sender, _value, _data);
		}
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value, _data);
	}

	function isContract(address _addr) view private returns (bool is_contract)
	{
		uint256 length;
		assembly
		{
			length := extcodesize(_addr)
		}
		return (length>0);
	}

	function burn(uint256 _value) external
	{
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		totalSupply = totalSupply.sub(_value);
		emit Burn(msg.sender, _value);
	}
}

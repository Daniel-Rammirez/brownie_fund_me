// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV2V3Interface.sol"; // importamos agregatorv3 para obtener la tasa de cambio de eth / usd
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256; // esto es para que al operar con uint256 no haga el efecto de redondeo y arroge otro resultado

    mapping(address => uint256) public adressToAmountFunded;

    address public owner;

    address[] public funders;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        // constructor es una funcion que se ejecuta inmediatamente de implementa el copntrato
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender; // por ende esta funcion asocia como dueño al que implementa el contrato
    }

    function fund() public payable {
        //al definir payable es una funcion de pago, y tendra asociado un valor (eth) se puede cambiar a Wei, Gwei o ETH (todos son equivalentes https://eth-converter.com/)
        //queremos poner una restriccion de minimo añadir 50 usd
        uint256 minimumUSD = 50 * 10**18; // esto de multiplar por 10**18 se hace para que todo tenga 18 decimales, recordemos que solidity no usa decimales, por tanto la unidad mas pequeña del eth que es el Wei lleva estoss 10**18 decimales
        // es decir, llevar cualquier cantidad de eth a Wei para no tener problemas con los decimales
        require(getConvertionRate(msg.value) >= minimumUSD, "Add more funds!!");
        adressToAmountFunded[msg.sender] += msg.value; // msg.sender y msg.value son keywords se cada Tx
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // con esta funcion vemos la version de la interfaz, una interfaz es un nuevo tipo de variable por eso se debe definir las variables que queramos que tengan esta estructura
        //AggregatorV3Interface interface_version = AggregatorV3Interface(
        //       0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //   ); //esta linea nos dice que tenemos un contrato (AggregatorV3Interface(...)) con las funciones definidas en la interfaz guardadas en esta direccion
        return priceFeed.version(); // es decir, creamos un contrato con las caracteristicas de la interzas, por lo que podemos ver la version que tiene
    } // acabamos de hacer una llamada a un contrato mediante un contrato desde nuestro contrato usando una interfaz

    //pero queremos saber el cambio eth/usd, para eso, usamos la funcion latestRoundData de AggregatorV3Interface

    function getPrice() public view returns (uint256) {
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //    0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);
        //  (uint80 roundId,
        //  int256 answer,
        //  uint256 startedAt,
        //  uint256 updatedAt,
        //  uint80 answeredInRound
        //  ) = priceFeed.latestRoundData(); // hay una forma mas bonita de escribir esta linea:
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); //320429083454 es la respuesta, pero si queremos dejarlo con los 18 decimales de la unidad mas pequeña (Wei) se multiplica por 10^10
    }

    //supongamos que envia 1000000000 Gwei que es igual a 1000000000000000000 Wei o 1 ETH, necesitamos entonces saber cuanto es en USD
    function getConvertionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10**18; // esta division es si o si
        return ethAmountInUsd; //nos da como retorno 3197003917570, pero debemos saber que falta dividirlo por 18 (solidity no usa decimales), lo que nos da 0,000003197003917570 como tasa de cambio (USD/Gwei)
    }

    function balaceContract() public view returns (uint256) {
        // esta funcion muestra el balance actual que tiene el contrato
        return address(this).balance;
    }

    function getEntranceFee() public view returns (uint256) {
        //minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        // un modifier se usa para cambiar el comportamiento de una funcion
        require(msg.sender == owner); // entonces si agrego el nombre del modifier a la funcion, ejecutara el modifier y luego la funcion
        _; // esto va si o si, para indicar que luego chequear el modifier siga con la funcion nomrmalmente
    }

    function withdraw() public payable onlyOwner {
        // require(msg.sender == owner); //la opcion2 es usar un modifier
        msg.sender.transfer(address(this).balance);
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            adressToAmountFunded[funders[fundersIndex]] = 0;
        }

        funders = new address[](0);
    }
}

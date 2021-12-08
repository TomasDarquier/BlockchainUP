// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Empenio is ERC1155Holder{
    
    address creador;
    address[] public contratosAprobados;
    mapping(uint256 => Propuesta) public propuestas;
    mapping(uint256 => OfertaDePrestamo[]) public ofertas;
    uint256 empenio = 1;

    //Representa los estados en los que se puede encontrar una operacion.
    enum Estado{
        CREADO,
        ACEPTADO,
        PAGADO,
        CANCELADO,
        VENCIDO
    }

    //Datos del address que decide listar un NFT para que este sea posiblemente empeniado.
    struct Propuesta{
        address NFT;
        uint256 tokenId;        
        address creador;
        uint256 cantOfertas;
        Estado estado;
    }
    
    //Recopila datos necesarios del address que decide prestar dinero.
    struct OfertaDePrestamo{
        address prestador;
        uint256 cantPrestamo;
        uint256 intereses;
        uint256 aRecibir;
        uint256 duracion;
        bool ofertaAceptada;
        uint256 momentoAceptacion;
    }

    constructor() {
       creador = msg.sender;
    }

    /*
    Recibe por parte del 'creador' recien definido, una lista de colecciones permitidas para
    ser empeniadas, debido a que son relativamente pocas las colecciones de NFT's con valor real.
    Evitando asi propuestas de empenio que puedan contener NFT's sin valor. 
    */
    function aprobarContratos(address nft) public{
        require(msg.sender == creador,"Solo el creador del contrato puede invocar esta funcion");
        contratosAprobados.push(nft);
    }


    /*
    Lista un NFT que se encuentre dentro de los contratos aprobados y este es transferido desde 
    quien invoca la funcion a este contrato.
    */
    function crearEmpenio(address _NFT, uint256 _tokenId) public{
        bool aprobado;
        for(uint256 i = 0; i < contratosAprobados.length; i++){
            if(_NFT == contratosAprobados[i]){
                aprobado = true;
                break;
            }           
        }

        require(aprobado == true, "El contrato no esta aprobado para el empenio de sus tokens");

        ERC1155 token = ERC1155(_NFT);
        
        bool nftAprobado = token.isApprovedForAll(msg.sender, address(this));
        require(nftAprobado == true, "El nft no tiene los permisos necesarios para ser transferido");
        require(token.balanceOf(msg.sender, _tokenId) > 0, "No sos propietario del token que deseas empeniar");
        
        token.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");

        propuestas[empenio].creador = msg.sender;
        propuestas[empenio].NFT = _NFT;
        propuestas[empenio].tokenId = _tokenId;
        propuestas[empenio].estado = Estado.CREADO;

        empenio++;

    }

    //Cancela el listado de un NFT y devuelve este a su duenio.
    function cancelarEmpenio(uint256 _idPropuesta) public{
        require(propuestas[_idPropuesta].creador == msg.sender,"Solo el creador del empenio puede cancelarlo");
        require(propuestas[_idPropuesta].estado == Estado.CREADO,"El empenio no se encuentra en estado de ser cancelado");
        
        propuestas[_idPropuesta].estado = Estado.CANCELADO;
        ERC1155 token = ERC1155(propuestas[_idPropuesta].NFT);
        token.safeTransferFrom(address(this), msg.sender, propuestas[_idPropuesta].tokenId, 1, "");
    }

    /*
    Crea una oferta sobre un NFT listado, es decir, se propone al address que listo el NFT seleccionado
    una oferta de empenio, expresando los intereses que se buscan y la duracion de la misma.
    Se transfiere el valor de la oferta de 'prestamo'.
    */
    function crearOferta(uint256 _idPropuesta, uint256 _intereses, uint256 _duracion) public payable{
        address _prestamista = msg.sender;
        uint256 _cantPrestamo = msg.value;
        require(propuestas[_idPropuesta].creador != address(0),"Propuesta seleccionada no valida");
        require(_cantPrestamo <= _prestamista.balance, "No dispones del suficiente balance para realizar la oferta");
        require(_cantPrestamo > 0, "El prestamo debe ser mayor a '0'");
        require(propuestas[_idPropuesta].estado == Estado.CREADO,"El NFT no esta disponible para recibir una oferta");
        require(_idPropuesta < empenio && _idPropuesta > 0,"Excediste los limites del mapping de propuestas disponibles");
        OfertaDePrestamo memory prestador = OfertaDePrestamo(_prestamista, _cantPrestamo, _intereses,_cantPrestamo + _intereses, _duracion, false, 0);
        ofertas[_idPropuesta].push(prestador);
        propuestas[_idPropuesta].cantOfertas++;
    } 

    //Cancela una oferta y devuelve los fondos a su creador.
    function cancelarOferta(uint256 _idPropuesta, uint256 _numOferta) public{
        require(ofertas[_idPropuesta][_numOferta].prestador == msg.sender, "Solo el que creo la oferta puede eliminarla");
        require(ofertas[_idPropuesta][_numOferta].ofertaAceptada == false, "La oferta ya fue aceptada, no es posible cancelarla");
        address payable prestador = payable(msg.sender);
        prestador.transfer(ofertas[_idPropuesta][_numOferta].cantPrestamo);
        delete ofertas[_idPropuesta][_numOferta];
    }

    /*
    Quien listo un NFT para ser empeniado, luego de analizar las ofertas que se le presentaron puede aceptar
    una, luego este recibe los fondos acordados y se registra el tiempo en el que se 'cerro el trato', para 
    asi poder validar si luego el pago se hizo dentro del plazo acrodado.
    */
    function aceptarOferta(uint256 _idPropuesta, uint256 _numOferta) public{
        require(propuestas[_idPropuesta].creador == msg.sender, "Solo el creador de la propuesta puede aceptar una oferta");
        require(_idPropuesta > 0 && _idPropuesta < empenio,"El id de propuesta proporcionado no es valido");
        require(_numOferta >= 0 && _numOferta < propuestas[_idPropuesta].cantOfertas,"El numero de oferta proporcionado no es valido");

        address payable receptor = payable(msg.sender);
        receptor.transfer(ofertas[_idPropuesta][_numOferta].cantPrestamo);

        ofertas[_idPropuesta][_numOferta].momentoAceptacion = block.timestamp;
        ofertas[_idPropuesta][_numOferta].ofertaAceptada = true;
        propuestas[_idPropuesta].estado = Estado.ACEPTADO;

    }

    /*
    Quien listo un NFT devuelve la cantidad exacta de wei previamente acordada, siempre y cuando este dentro
    del plazo de tiempo previamente acordado.
    */
    function pagarOferta(uint256 _idPropuesta, uint256 _numOferta) public payable{
        require(propuestas[_idPropuesta].creador == msg.sender, "Solo el creador de la propuesta puede pagar");
        require(propuestas[_idPropuesta].estado == Estado.ACEPTADO, "La propuesta no esta en etapa de pago");
        require(ofertas[_idPropuesta][_numOferta].ofertaAceptada == true,"No se puede pagar una oferta que no fue aceptada");
        uint256 fechaLimite = ofertas[_idPropuesta][_numOferta].momentoAceptacion + ofertas[_idPropuesta][_numOferta].duracion * 1 days;
        require(block.timestamp < fechaLimite,"Ya paso el plazo de pago");
        require(msg.value == ofertas[_idPropuesta][_numOferta].aRecibir, "Tiene que devolver la cantidad exacta acordada");
        
        ERC1155 token = ERC1155(propuestas[_idPropuesta].NFT);
        token.safeTransferFrom(address(this), msg.sender, propuestas[_idPropuesta].tokenId, 1, "");

        address payable prestamista = payable(ofertas[_idPropuesta][_numOferta].prestador);
        prestamista.transfer(msg.value);
        propuestas[_idPropuesta].estado = Estado.PAGADO;

    }

    /*
    Una vez que paso el plazo de tiempo acordado y el prestamista no recibio su pago, este puede reclamar el
    NFT que el otro usuario dio de garantia.
    */
    function reclamarDinero(uint256 _idPropuesta, uint256 _numOferta) public{
        require(ofertas[_idPropuesta][_numOferta].prestador == msg.sender, "Solo el creador de la oferta puede reclamar el dinero una vez vencido el plazo");
        require(propuestas[_idPropuesta].estado == Estado.ACEPTADO,"La oferta no fue aceptada, fue cancelada o ya fue pagada");
        uint256 fechaLimite = ofertas[_idPropuesta][_numOferta].momentoAceptacion + ofertas[_idPropuesta][_numOferta].duracion * 1 days;
        require(block.timestamp > fechaLimite,"El plazo de pago aun no finalizo");

        ERC1155 token = ERC1155(propuestas[_idPropuesta].NFT);
        token.safeTransferFrom(address(this),msg.sender, propuestas[_idPropuesta].tokenId, 1, "");
        propuestas[_idPropuesta].estado = Estado.VENCIDO;
    }

    

}

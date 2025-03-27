import "forge-std/Test.sol";
import "solidity-stringutils/strings.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";


abstract contract DiamondUtils is Test {
    using strings for *;

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        //get string of contract methods
        string[] memory cmd = new string[](5);
        cmd[0] = "forge";
        cmd[1] = "inspect";
        cmd[2] = _facetName;
        cmd[3] = "methods";
        cmd[4] = "--json";
        bytes memory res = vm.ffi(cmd);
        
        string memory st = string(res);
        console.log(st);

        // extract function signatures and take first 4 bytes of keccak
        strings.slice memory s = st.toSlice();

        // Skip TRACE lines if any
        strings.slice memory nl = "\n".toSlice();
        strings.slice memory trace = "TRACE".toSlice();
        while (s.contains(trace)) {
            s.split(nl);
        }

        strings.slice memory colon = ":".toSlice();
        strings.slice memory comma = ",".toSlice();
        strings.slice memory dbquote = '"'.toSlice();
        selectors = new bytes4[]((s.count(colon)));
        console.log(_facetName);
        console.log(selectors.length);

        for (uint i = 0; i < selectors.length; i++) {
            s.split(dbquote); // advance to next doublequote
            // split at colon, extract string up to next doublequote for methodname
            strings.slice memory method = s.split(colon).until(dbquote);
            selectors[i] = bytes4(method.keccak());
            console.logBytes4(selectors[i]);
            strings.slice memory selectr = s.split(comma).until(dbquote); // advance s to the next comma
        }
        // console.logBytes4(selectors[0]);
        return selectors;
    }
}

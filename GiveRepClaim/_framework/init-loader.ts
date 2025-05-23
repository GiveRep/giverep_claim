import * as package_onchain_1 from "../_dependencies/onchain/0x1/init";
import * as package_onchain_2 from "../_dependencies/onchain/0x2/init";
import * as package_onchain_eff887fb31a8c019cdb6716633ed7b4929b7c6c59eb0e278c08a3547ab358654 from "../giverep_claim/init";
import {StructClassLoader} from "./loader";

function registerClassesOnchain(loader: StructClassLoader) { package_onchain_1.registerClasses(loader);
package_onchain_2.registerClasses(loader);
package_onchain_eff887fb31a8c019cdb6716633ed7b4929b7c6c59eb0e278c08a3547ab358654.registerClasses(loader);
 }

export function registerClasses(loader: StructClassLoader) { registerClassesOnchain(loader); }

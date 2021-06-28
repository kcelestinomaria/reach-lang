import {loadStdlib} from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';

(async () => {
  const stdlib = await loadStdlib();
  const startingBalance = stdlib.parseCurrency(100);
  const isAlgo = stdlib.connector == 'ALGO';

  const numOfBuyers = isAlgo ? 4 : 10;
  const accFunder = await stdlib.newTestAccount(startingBalance);
  const accBuyerArray = await Promise.all(
    Array.from({ length: numOfBuyers }, () =>
      stdlib.newTestAccount(startingBalance)
    )
  );

  const ctcFunder = accFunder.deploy(backend);
  const ctcInfo   = ctcFunder.getInfo();

  const funderParams = {
    ticketPrice: stdlib.parseCurrency(5),
    deadline: isAlgo ? 3 : 5,
  };

  const bidHistory = {};

  await Promise.all([
    backend.Funder(ctcFunder, {
      showOutcome: (addr) => console.log(`Funder saw ${stdlib.formatAddress(addr)} won.`),
      getParams: () => funderParams,
    }),
  ].concat(
    accBuyerArray.map((accBuyer, i) => {
      const ctcBuyer = accBuyer.attach(backend, ctcInfo);
      const Who = `Buyer ${i}`;
      return backend.Buyer(ctcBuyer, {
        showOutcome: (outcome) => {
          console.log(`${Who} saw they ${stdlib.addressEq(outcome, accBuyer) ? 'won' : 'lost'}.`);
        },
        shouldBuyTicket : () => !bidHistory[Who] && Math.random() < 0.5,
        showPurchase: (addr) => {
          if (stdlib.addressEq(addr, accBuyer)) {
            console.log(`${Who} bought a ticket.`);
            bidHistory[Who] = true;
          }
        }
      });
    })
  ));

})();

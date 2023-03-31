import table from './main';

(async () => {
  let E = await table.getModel('Env');
  let E1 = await E.create(
    {
      tracking: ["https://help.hmdc.harvard.edu/Ticket/Display.html?id=99999"],
      owner: "example@person.com",
      subnet: 2886795264,
      cidr: "172.17.0.0/24",
      status: "active"
    });
  console.log(E1);
})();
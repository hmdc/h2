import table from './main';

(async () => {
  let E = await table.getModel('Env');
  let E1 = await E.create({ tracking: ["https://www.google.com"], owner: "abc@abc.com", subnet: 12345, status: "onboarding" });
  console.log(E1);
  let user = await E.find({ gs1sk: { "begins": "env#abc@abc.com" } }, { index: 'gs1' });
  console.log(user);
})();
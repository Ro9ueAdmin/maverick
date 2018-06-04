type IP::Address::V6::Compressed = Pattern[
  /\A:(:|(:[[:xdigit:]]{1,4}){1,7})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){1}(:|(:[[:xdigit:]]{1,4}){1,6})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){2}(:|(:[[:xdigit:]]{1,4}){1,5})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){3}(:|(:[[:xdigit:]]{1,4}){1,4})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){4}(:|(:[[:xdigit:]]{1,4}){1,3})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){5}(:|(:[[:xdigit:]]{1,4}){1,2})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){6}(:|(:[[:xdigit:]]{1,4}){1,1})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){7}:(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/
]

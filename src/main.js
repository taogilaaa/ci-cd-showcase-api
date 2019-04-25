const { ApolloServer, gql } = require('apollo-server');

const typeDefs = gql`
  type Query {
    "A simple type for getting started!"
    hello: String
    "A resolver that takes 2 number 'x' and 'y' and sum it!"
    add(x: Int!, y: Int!): Int!
  }
`;

const resolvers = {
  Query: {
    hello: () => 'world',
    add: (_, { x, y }) => x + y,
  },
};

const server = new ApolloServer({
  typeDefs,
  resolvers,
});

server.listen().then(({ url }) => {
  // eslint-disable-next-line no-console
  console.log(`🚀 Server ready at ${url}`);
});

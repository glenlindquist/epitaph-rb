import React from 'react';

let newCivilization = () => {
  fetch('/civilization/new')
  .then((response) => {
    return response.json();
  })
  .then((myJson) => {
    console.log(myJson);
  });
}

class App extends React.Component {
  componentDidMount(){
    newCivilization();
  }

  render() {
    return <h1>Hello...</h1>;
  }
}

export default App;

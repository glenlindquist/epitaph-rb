import React from 'react';

class Civilization extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <div>
        Civ: {this.props.name}
        {this.props.available_technologies.map((tech)=>
          <div key={tech}>
            <button onClick={(e) => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</button>
          </div>
        )}
      </div>
    );
  }
}

export default Civilization;

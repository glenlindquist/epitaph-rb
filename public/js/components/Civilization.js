import React from 'react';

class Civilization extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      status: this.props.status,
      technologies: this.props.technologies,
      name: this.props.name,
      description: this.props.description,
      tech_chance: this.props.tech_chance,
      event_chances: this.props.event_chances,
      vocab: this.props.event_chances,
      notification_pitch: this.props.notification_pitch,
      available_technologies: this.props.available_technologies
    }

    this.acquireTechnology = this.acquireTechnology.bind(this)
  }

  componentDidUpdate(){
  }

  acquireTechnology(technologyName){
    fetch('/acquire_technology', {
      method: "post",
      body: JSON.stringify({
        civilization: this.state,
        technology_name: technologyName
      }),
      headers: { 'Content-type': 'application/json' }
    })
    .then((response) => {
      return response.json();
    })
    .then((data) => {
      console.log(data);
      this.setState(data.civilization);
      // update text w/ data.text
    });
  }

  render() {
    return (
      <div>
        Civ: {this.props.name}
        {this.state.available_technologies.map((tech)=>
          <div key={tech}>
            <button onClick={(e) => this.acquireTechnology(tech)}>{tech}</button>
          </div>
        )}
      </div>
    );
  }
}

export default Civilization;

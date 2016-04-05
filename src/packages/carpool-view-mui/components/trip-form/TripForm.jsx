import DesktopLayout from '../layout/DesktopLayout'
import PageRoot from '../layout/PageRoot'
import { TAPi18n } from 'meteor/tap:i18n';
import AutoComplete from 'material-ui/lib/auto-complete';
import { TextField, DatePicker, TimePicker, RaisedButton, Snackbar, RadioButtonGroup, RadioButton } from 'material-ui'

// TODO: replace this with real function
const getLocationSuggestions = (inputVal, callback) => {
  return ['Suggestions', 'For', inputVal]
}

class TripFormBase extends React.Component {
  constructor(props) {
    super(props)
    const currDate = new Date()
    this.state = {
      from: '',
      to: '',
      fromSuggestions: [],
      toSuggestions: [],
      date: new Date(),
      time: new Date(),
      role: 'driver',
    }
  }

  valueChanged(valueName, e) {
    this.setState({[valueName]: e.target.value})
  }

  muiValueChanged(valueName, _, value) {
    this.setState({[valueName]: value})
  }

  fromInputUpdate (val) {
    getLocationSuggestions(val, (suggestions) => this.setState({
      fromSuggestions: suggestions
    }))
    this.setState({
      from: val,
    })
  }

  toInputUpdate (val) {
    getLocationSuggestions(val, (suggestions) => this.setState({
      toSuggestions: suggestions
    }))
    this.setState({
      to: val,
    })
  }

  submitForm () {
    // TODO connect with backend or smth
    console.log('Should submit form with prams:', {
      from: this.state.from,
      to: this.state.to,
      date: this.state.date,
      time: this.state.time,
      role: this.state.role,
    })
  }

  render() {
    return (
      <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', width: this.props.width, padding: 5}}>
        <AutoComplete floatingLabelText={TAPi18n.__('labelFrom')} className="mui-input" dataSource={this.state.fromSuggestions} onUpdateInput={this.fromInputUpdate.bind(this)} />
        <AutoComplete floatingLabelText={TAPi18n.__('labelTo')} className="mui-input" dataSource={this.state.toSuggestions} onUpdateInput={this.toInputUpdate.bind(this)} />
        <DatePicker hintText={TAPi18n.__('labelDate')} style={{marginTop: 20}} value={this.state.date} onChange={this.muiValueChanged.bind(this, 'date')} />
        <TimePicker hintText={TAPi18n.__('labelTime')} style={{marginTop: 20}} format='24hr' value={this.state.time} onChange={this.muiValueChanged.bind(this, 'time')} />
        <RadioButtonGroup name="driver" valueSelected={this.state.role} style={{marginTop: 20, marginBottom: 20}} onChange={this.muiValueChanged.bind(this, 'role')}>
          <RadioButton
            value="driver"
            label="Driver"
          />
          <RadioButton
            value="passenger"
            label="Passenger"
          />
        </RadioButtonGroup>
        <RaisedButton label={'Submit'} primary={true} onClick={this.submitForm.bind(this)} />
      </div>
    )
  }
}

TripForm = PageRoot(TripFormBase)

export default TripForm

// TODO Extract to css some day or replace with current styles
var styles = {
  datesWrapper: {
    display: 'flex',
  },
  buttonsWrapper: {
    display: 'flex',
    justifyContent: 'center',
  },
  button: {
    width: 'auto',
  },
  fullWidthInput: {
    width: 300,
  },
  timeInput: {
    width: 80,
  },
  dateInput: {
    width: 100,
  },
}

// TripForm = PageRoot(TripFormBase)
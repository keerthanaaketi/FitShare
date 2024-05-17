import SwiftUI
import HealthKit

struct WorkoutView: View {
    var workouts: [HKWorkout]
    var workoutGoal: Int

    @State private var showDetails = false

    var totalMinutes: Int {
        workouts.reduce(0) { total, workout in
            return total + Int(workout.duration / 60)
        }
    }

    var body: some View {
        let progress = min(max(Double(totalMinutes) / Double(workoutGoal), 0.0), 1.0)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    Text("Workouts")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                AdaptiveText(text: "\(totalMinutes) / \(workoutGoal) mins", font: .title2, color: .blue)
                Spacer()
                Text("Remaining: \(workoutGoal - totalMinutes) mins")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            ProgressView(value: progress)
                .progressViewStyle(CustomProgressViewStyle(color: .green))
                .onTapGesture {
                    showDetails.toggle()
                }

            if showDetails {
                VStack {
                    ForEach(workouts, id: \.uuid) { workout in
                        HStack {
                            Text(readableWorkoutActivityType(workout.workoutActivityType))
                                .font(.caption)
                            Spacer()
                            Text("\(Int(workout.duration / 60)) min")
                                .font(.caption)
                        }
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity)
                //.padding()
                .background(Color.gray.opacity(0.1))
                //.cornerRadius(10)
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }

    func readableWorkoutActivityType(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .americanFootball: return "American Football"
        case .archery: return "Archery"
        case .australianFootball: return "Australian Football"
        case .badminton: return "Badminton"
        case .baseball: return "Baseball"
        case .basketball: return "Basketball"
        case .bowling: return "Bowling"
        case .boxing: return "Boxing"
        case .climbing: return "Climbing"
        case .coreTraining: return "Core Training"
        case .cricket: return "Cricket"
        case .crossCountrySkiing: return "Cross Country Skiing"
        case .crossTraining: return "Cross Training"
        case .curling: return "Curling"
        case .cycling: return "Cycling"
        case .dance: return "Dance"
        case .danceInspiredTraining: return "Dance Inspired Training"
        case .downhillSkiing: return "Downhill Skiing"
        case .elliptical: return "Elliptical"
        case .equestrianSports: return "Equestrian Sports"
        case .fencing: return "Fencing"
        case .fishing: return "Fishing"
        case .functionalStrengthTraining: return "Functional Strength Training"
        case .golf: return "Golf"
        case .gymnastics: return "Gymnastics"
        case .handball: return "Handball"
        case .hiking: return "Hiking"
        case .hockey: return "Hockey"
        case .hunting: return "Hunting"
        case .lacrosse: return "Lacrosse"
        case .martialArts: return "Martial Arts"
        case .mindAndBody: return "Mind and Body"
        case .mixedMetabolicCardioTraining: return "Mixed Metabolic Cardio Training"
        case .paddleSports: return "Paddle Sports"
        case .play: return "Play"
        case .preparationAndRecovery: return "Preparation and Recovery"
        case .racquetball: return "Racquetball"
        case .rowing: return "Rowing"
        case .rugby: return "Rugby"
        case .running: return "Running"
        case .sailing: return "Sailing"
        case .skatingSports: return "Skating Sports"
        case .snowboarding: return "Snowboarding"
        case .snowSports: return "Snow Sports"
        case .soccer: return "Soccer"
        case .softball: return "Softball"
        case .squash: return "Squash"
        case .stairClimbing: return "Stair Climbing"
        case .surfingSports: return "Surfing Sports"
        case .swimming: return "Swimming"
        case .tableTennis: return "Table Tennis"
        case .tennis: return "Tennis"
        case .trackAndField: return "Track and Field"
        case .traditionalStrengthTraining: return "Traditional Strength Training"
        case .volleyball: return "Volleyball"
        case .walking: return "Walking"
        case .waterFitness: return "Water Fitness"
        case .waterPolo: return "Water Polo"
        case .waterSports: return "Water Sports"
        case .wrestling: return "Wrestling"
        case .yoga: return "Yoga"
        default: return "Unknown"
        }
    }
}

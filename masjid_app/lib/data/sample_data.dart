import '../models/announcement.dart';
import '../models/event.dart';

final List<Announcement> sampleAnnouncements = [
  Announcement(
    id: '1',
    title: 'Jumu\'ah Prayer — New Time',
    body:
        'Jumu\'ah (Friday) prayer will now begin at 1:30 PM. Please arrive early for the khutbah.',
    category: 'Reminder',
    date: DateTime(2026, 5, 22),
  ),
  Announcement(
    id: '2',
    title: 'Ramadan Iftar Program',
    body:
        'The Masjid will host nightly Iftar dinners throughout Ramadan. All are welcome. Please bring a dish to share.',
    category: 'Event',
    date: DateTime(2026, 5, 20),
  ),
  Announcement(
    id: '3',
    title: 'Quran Class — Beginners',
    body:
        'A new Quran recitation class for beginners starts every Saturday at 5:00 PM. Suitable for all ages.',
    category: 'Education',
    date: DateTime(2026, 5, 18),
  ),
  Announcement(
    id: '4',
    title: 'Masjid Renovation Fund',
    body:
        'We are raising funds for the new expansion wing. Donations can be made online or at the masjid reception.',
    category: 'Notice',
    date: DateTime(2026, 5, 15),
  ),
  Announcement(
    id: '5',
    title: 'Youth Halaqa — Every Thursday',
    body:
        'Weekly youth circle for brothers aged 15–25, Thursdays at 7:30 PM in the main hall.',
    category: 'Education',
    date: DateTime(2026, 5, 12),
  ),
];

final List<MasjidEvent> sampleEvents = [
  MasjidEvent(
    id: '1',
    title: 'Eid Al-Adha Celebration',
    description:
        'Join us for Eid prayer followed by a community feast. Bring your family and friends.',
    dateTime: DateTime(2026, 6, 17, 7, 30),
    location: 'Main Prayer Hall',
    category: 'Celebration',
  ),
  MasjidEvent(
    id: '2',
    title: 'Monthly Community Dinner',
    description:
        'A warm community dinner open to all. Volunteers needed from 5 PM to help with setup.',
    dateTime: DateTime(2026, 5, 30, 18, 0),
    location: 'Masjid Courtyard',
    category: 'Community',
  ),
  MasjidEvent(
    id: '3',
    title: 'Islamic Finance Workshop',
    description:
        'Learn about halal investment, mortgages, and financial planning from an Islamic perspective.',
    dateTime: DateTime(2026, 6, 5, 19, 0),
    location: 'Conference Room',
    category: 'Education',
  ),
  MasjidEvent(
    id: '4',
    title: 'Sisters\' Halaqa',
    description:
        'Monthly circle for sisters — this month\'s topic: "Patience and gratitude in daily life".',
    dateTime: DateTime(2026, 6, 7, 14, 0),
    location: 'Sisters\' Wing',
    category: 'Education',
  ),
  MasjidEvent(
    id: '5',
    title: 'Blood Donation Drive',
    description:
        'In partnership with the Red Crescent. Fasting does not invalidate blood donation.',
    dateTime: DateTime(2026, 6, 12, 9, 0),
    location: 'Masjid Entrance Hall',
    category: 'Community',
  ),
];

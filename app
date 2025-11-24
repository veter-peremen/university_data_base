using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using UniversityManagement;
namespace UniversityManagement
{
    // 1. Базовый класс "Человек"
    public class Person
    {
        // 3. Приватное статическое поле счётчика
        private static int _personalIdCounter = 0;
        // Автоматически присваиваемый уникальный личный номер
        public int PersonalId { get; }
        private string _firstName;
        private string _lastName;
        private string _middleName;
        private DateTime _birthDate;
        public string FirstName
        {
            get => _firstName;
            set
            {
                if (string.IsNullOrWhiteSpace(value))
                    throw new ArgumentException("Имя не может быть пустым");
                _firstName = value;
            }
        }
        public string LastName
        {
            get => _lastName;
            set
            {
                if (string.IsNullOrWhiteSpace(value))
                    throw new ArgumentException("Фамилия не может быть пустой");
                   
                    _lastName = value;
            }
        }
        public string MiddleName
        {
            get => _middleName;
            set => _middleName = value ?? string.Empty;
        }
        public DateTime BirthDate
        {
            get => _birthDate;
            set
            {
                if (value > DateTime.Now)
                    throw new ArgumentException("Дата рождения не может быть  в будущем");
            if (DateTime.Now.Year - value.Year > 150)
                    throw new ArgumentException("Некорректная дата рождения");
                   
                    _birthDate = value;
            }
        }
        public int Age => DateTime.Now.Year - _birthDate.Year -
        (DateTime.Now.DayOfYear < _birthDate.DayOfYear ? 1 :
       0);
        public string FullName => $"{LastName} {FirstName}{MiddleName}".Trim();
 public Person(string firstName, string lastName, DateTime birthDate,
string middleName = "")
    {
        PersonalId = Interlocked.Increment(ref _personalIdCounter);
        FirstName = firstName;
        LastName = lastName;
        MiddleName = middleName;
        BirthDate = birthDate;
        // 2. Автоматическое внесение в статический класс
        PersonRegistry.RegisterPerson(this);
    }
    public override string ToString()
    {
        return $"{FullName}, Дата рождения: {BirthDate:dd.MM.yyyy}, Возраст: { Age}, Личный номер: { PersonalId}";
    }
    public override bool Equals(object obj)
    {
        return obj is Person person && PersonalId == person.PersonalId;
    }
    public override int GetHashCode()
    {
        return PersonalId.GetHashCode();
    }
}
// 2. Статический класс для хранения данных всех людей
public static class PersonRegistry
{
    private static readonly Dictionary<int, Person> _people = new
   Dictionary<int, Person>();
    public static int TotalPeople => _people.Count;
    public static void RegisterPerson(Person person)
    {
        if (person == null)
            throw new ArgumentNullException(nameof(person));
        if (!_people.ContainsKey(person.PersonalId))
        {
            _people[person.PersonalId] = person;
        }
    }
    public static Person GetPersonById(int personalId)
    {
        return _people.TryGetValue(personalId, out var person) ? person :
       null;
    }
    public static IEnumerable<Person> GetAllPeople()
    {
        return _people.Values.ToList().AsReadOnly();
    }
    public static bool RemovePerson(int personalId)
    {
        return _people.Remove(personalId);
    }
    public static bool PersonExists(int personalId)
    {
        return _people.ContainsKey(personalId);
    }
}
// 4. Класс студента, унаследованный от класса "Человек"
public class Student : Person
{
    private double _averageGrade;
    public double AverageGrade
    {
        get => _averageGrade;
        set
        {
            if (value < 0 || value > 100)
                throw new ArgumentException("Средний балл должен быть от 0 до 100");
               
                _averageGrade = value;
        }
    }
    // Номер зачетной книжки (присваивается университетом)
    public string RecordBookNumber { get; set; }
    public Student(string firstName, string lastName, DateTime birthDate,
    double averageGrade, string middleName = "")
    : base(firstName, lastName, birthDate, middleName)
    {
        AverageGrade = averageGrade;
    }
    public override string ToString()
    {
        return $"{base.ToString()}, Средний балл: {AverageGrade:F2}" + (string.IsNullOrEmpty(RecordBookNumber) ? "" : $", Зачетка: { RecordBookNumber}");
    }
}
public interface IStudentRepository
{
    void AddStudent(Student student);
    bool RemoveStudent(Student student);
    Student FindStudentByName(string firstName, string lastName);
    Student FindStudentByRecordBook(string recordBookNumber);
    Student FindStudentByPersonalId(int personalId);
    IEnumerable<Student> GetAllStudents();
    void SaveStudents();
    void LoadStudents();
}
public interface IStudentValidator
{
    bool Validate(Student student);
}
public class University
{
    private readonly List<Student> _students;
    private readonly IStudentRepository _repository;
    private readonly IStudentValidator _validator;
    // 5a. Нестатический счётчик для номеров зачётных книжек
    private int _recordBookCounter = 0;
    public string UniversityName { get; }
    // 5b. Словари для быстрого доступа по идентификаторам
    private readonly Dictionary<string, Student> _studentsByRecordBook =
   new Dictionary<string, Student>();
    private readonly Dictionary<int, Student> _studentsByPersonalId = new
   Dictionary<int, Student>();
    public University(string universityName, IStudentRepository
   repository, IStudentValidator validator)
    {
        UniversityName = universityName ?? throw new
       ArgumentNullException(nameof(universityName));
        _students = new List<Student>();
        _repository = repository ?? throw new
       ArgumentNullException(nameof(repository));
        _validator = validator ?? throw new
       ArgumentNullException(nameof(validator));
    }
    // 5a. Метод для генерации номера зачетной книжки
    private string GenerateRecordBookNumber()
    {
        _recordBookCounter++;
        return $"{UniversityName.Substring(0, 3).ToUpper()}-{ _recordBookCounter: D6} ";
    }
    public void AddStudent(Student student)
    {
        if (student == null)
            throw new ArgumentNullException(nameof(student), "Студент не может быть null");
    if (!_validator.Validate(student))
            throw new ArgumentException("Некорректные данные студента");
        if (_students.Contains(student))
            throw new InvalidOperationException("Студент уже существует в университете");
    // Проверяем, не учится ли уже студент в этом университете
 if (_studentsByPersonalId.ContainsKey(student.PersonalId))
            throw new InvalidOperationException("Студент с таким личным номером уже учится в университете");
            // Присваиваем номер зачетной книжки
            student.RecordBookNumber = GenerateRecordBookNumber();
        _students.Add(student);
        _studentsByRecordBook[student.RecordBookNumber] = student;
        _studentsByPersonalId[student.PersonalId] = student;
        _repository.AddStudent(student);
    }
    public bool RemoveStudent(Student student)
    {
        if (student == null)
            return false;
        bool removed = _students.Remove(student);
        if (removed)
        {
            _studentsByRecordBook.Remove(student.RecordBookNumber);
            _studentsByPersonalId.Remove(student.PersonalId);
            _repository.RemoveStudent(student);
        }
        return removed;
    }
    // 5b. Методы для взаимодействия по различным идентификаторам
    public Student FindStudentByName(string firstName, string lastName)
    {
        return _students.FirstOrDefault(s =>
        s.FirstName.Equals(firstName,
       StringComparison.OrdinalIgnoreCase) &&
        s.LastName.Equals(lastName,
       StringComparison.OrdinalIgnoreCase));
    }
    public Student FindStudentByRecordBook(string recordBookNumber)
    {
        return _studentsByRecordBook.TryGetValue(recordBookNumber, out
       var student) ? student : null;
    }
    public Student FindStudentByPersonalId(int personalId)
    {
        return _studentsByPersonalId.TryGetValue(personalId, out var
       student) ? student : null;
    }
    public Person FindPersonByPersonalId(int personalId)
    {
        var student = FindStudentByPersonalId(personalId);
        if (student != null)
            return student;
        // Если студент не найден в университете, ищем в общем реестре людей
    return PersonRegistry.GetPersonById(personalId);
    }
    public IEnumerable<Student> GetAllStudents()
    {
        return _students.AsReadOnly();
    }
    public int StudentCount => _students.Count;
    public void SaveData()
    {
        _repository.SaveStudents();
    }
    public void LoadData()
    {
        _repository.LoadStudents();
        _students.Clear();
        _studentsByRecordBook.Clear();
        _studentsByPersonalId.Clear();
        var students = _repository.GetAllStudents();
        _students.AddRange(students);
        foreach (var student in students)
        {
            _studentsByRecordBook[student.RecordBookNumber] = student;
            _studentsByPersonalId[student.PersonalId] = student;
            if (student.RecordBookNumber != null &&

           student.RecordBookNumber.StartsWith(UniversityName.Substring(0,
           3).ToUpper()))
            {
                var parts = student.RecordBookNumber.Split('-');
                if (parts.Length == 2 && int.TryParse(parts[1], out int
               number))
                {
                    _recordBookCounter = Math.Max(_recordBookCounter,
                   number);
                }
            }
        }
    }
}
public class StudentValidator : IStudentValidator
{
    public bool Validate(Student student)
    {
        if (student == null)
            return false;
        try
        {
            var tempFirstName = student.FirstName;
            var tempLastName = student.LastName;
            var tempBirthDate = student.BirthDate;
            var tempGrade = student.AverageGrade;
            if (student.Age < 16 || student.Age > 100)
                return false;
            return true;
        }
        catch (ArgumentException)
        {
            return false;
        }
    }
}
}
namespace DataAccess
{
    using UniversityManagement;
    public class StudentsRepository : IStudentRepository
    {
        private readonly List<Student> _students;
        private readonly string _filePath;
        public StudentsRepository(string filePath = "students.json")
        {
            _students = new List<Student>();
            _filePath = filePath ?? throw new
           ArgumentNullException(nameof(filePath));
        }
        public void AddStudent(Student student)
        {
            if (student == null)
                throw new ArgumentNullException(nameof(student));
            if (!_students.Contains(student))
            {
                _students.Add(student);
            }
        }
        public bool RemoveStudent(Student student)
        {
            return _students.Remove(student);
        }
        public Student FindStudentByName(string firstName, string lastName)
        {
            return _students.FirstOrDefault(s =>
            s.FirstName.Equals(firstName,
           StringComparison.OrdinalIgnoreCase) &&
            s.LastName.Equals(lastName,
           StringComparison.OrdinalIgnoreCase));
        }
        public Student FindStudentByRecordBook(string recordBookNumber)
        {
            return _students.FirstOrDefault(s =>
            s.RecordBookNumber == recordBookNumber);
        }
        public Student FindStudentByPersonalId(int personalId)
        {
            return _students.FirstOrDefault(s => s.PersonalId == personalId);
        }
        public IEnumerable<Student> GetAllStudents()
        {
            return _students.AsReadOnly();
        }
        public void SaveStudents()
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                };
                var json = JsonSerializer.Serialize(_students, options);
                File.WriteAllText(_filePath, json);
                Console.WriteLine($"Данные сохранены в файл: {_filePath}");
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Ошибка при сохранении данных: { ex.Message }", ex);
            }
        }
        public void LoadStudents()
        {
            try
            {
                if (!File.Exists(_filePath))
                {
                    Console.WriteLine($"Файл {_filePath} не существует. Будет создан новый при сохранении.");
                return;
                }
                var json = File.ReadAllText(_filePath);
                var options = new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                };
                var students =
               JsonSerializer.Deserialize<List<Student>>(json, options);
                _students.Clear();
                if (students != null)
                {
                    _students.AddRange(students);
                    Console.WriteLine($"Загружено {_students.Count} студентов из файла: { _filePath}");
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Ошибка при загрузке данных: { ex.Message }", ex);
            }
        }
    }
}
class Program
{
    static void Main()
    {
        try
        {
            var repository = new DataAccess.StudentsRepository();
            var validator = new UniversityManagement.StudentValidator();
            var university = new UniversityManagement.University("МГУ", repository, validator);
            var student1 = new UniversityManagement.Student("Иван", "Петров", new DateTime(2000, 5, 15), 85.5, "Сергеевич");
            var student2 = new UniversityManagement.Student("Мария", "Иванова", new DateTime(2001, 3, 20), 92.0);
            university.AddStudent(student1);
            university.AddStudent(student2);
            Console.WriteLine($"Всего людей в реестре:{ UniversityManagement.PersonRegistry.TotalPeople}");
        var foundByRecordBook =
university.FindStudentByRecordBook(student1.RecordBookNumber);
            var foundByPersonalId =
           university.FindStudentByPersonalId(student2.PersonalId);
            var personFromRegistry = UniversityManagement.PersonRegistry.GetPersonById(student1.PersonalId);
            Console.WriteLine($"Найден по зачетке: {foundByRecordBook}");
            Console.WriteLine($"Найден по личному номеру: { foundByPersonalId}");
        Console.WriteLine($"Из реестра людей: {personFromRegistry}");
            university.SaveData();
            Console.WriteLine("\nВсе студенты университета:");
            foreach (var student in university.GetAllStudents())
            {
                Console.WriteLine(student);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Произошла ошибка: {ex.Message}");
        }
    }
}
